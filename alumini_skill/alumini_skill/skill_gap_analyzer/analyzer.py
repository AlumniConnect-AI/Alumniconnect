"""
Core Skill Gap Analyzer Engine for EduBridge AI.
Combines exact taxonomy matching, semantic similarity (TF-IDF/Cosine), weighted scoring,
category breakdown, and integrated course/project recommendation pipelines.
"""

from typing import List, Dict, Any, Optional, Tuple, Set
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from .models import (
    SkillGapRequest,
    JobDescriptionGapRequest,
    SkillGapResponse,
    SkillDetail,
    CategoryScore,
    CourseRecommendation,
    ProjectRecommendation,
)
from .taxonomy import (
    SKILL_TAXONOMY,
    normalize_skill,
    categorize_skill,
    extract_skills_from_text,
    CANONICAL_TO_CATEGORY,
)
from .benchmarks import BENCHMARK_ROLES, get_benchmark_role
from .recommender import CourseRecommender, ProjectRecommender


class SkillGapAnalyzer:
    """
    Main AI engine for Skill Gap Detection, Readiness Index Scoring,
    and targeted skilling recommendations.
    """

    def __init__(self):
        self.course_recommender = CourseRecommender()
        self.project_recommender = ProjectRecommender()
        self._init_vectorizer()

    def _init_vectorizer(self):
        """Prepares TF-IDF vocabulary for semantic skill similarity fallback."""
        corpus = list(CANONICAL_TO_CATEGORY.keys()) + [
            "Data Structures Algorithms", "REST API Development", "Cloud Architecture AWS Azure GCP",
            "Machine Learning Deep Learning AI", "Continuous Integration Deployment CI CD",
            "Frontend UI UX React Angular Vue", "Backend Server Microservices Database"
        ]
        self.vectorizer = TfidfVectorizer(ngram_range=(1, 2), stop_words="english")
        self.vectorizer.fit(corpus)

    def _compute_semantic_similarity(self, skill_a: str, skill_b: str) -> float:
        """Computes cosine similarity between two skill strings."""
        if not skill_a or not skill_b:
            return 0.0
            
        a_norm = skill_a.strip().lower()
        b_norm = skill_b.strip().lower()
        
        if a_norm == b_norm:
            return 1.0
            
        # Quick substring check
        if a_norm in b_norm or b_norm in a_norm:
            len_ratio = min(len(a_norm), len(b_norm)) / max(len(a_norm), len(b_norm))
            if len_ratio > 0.5:
                return max(0.85, len_ratio)
                
        try:
            vecs = self.vectorizer.transform([a_norm, b_norm])
            sim = cosine_similarity(vecs[0:1], vecs[1:2])[0][0]
            return float(sim)
        except Exception:
            return 0.0

    def analyze(self, request: SkillGapRequest) -> SkillGapResponse:
        """
        Performs end-to-end skill gap analysis for a student against a target role benchmark
        or custom skill requirements list.
        """
        student_raw = request.student_skills or []
        student_normalized_map: Dict[str, str] = {
            s: normalize_skill(s) for s in student_raw if s and s.strip()
        }
        student_canonical_set: Set[str] = set(student_normalized_map.values())

        # Determine target role benchmark or custom requirements
        benchmark = None
        target_role_name = request.target_role or "Custom Role"
        role_id = None
        
        if request.custom_benchmark_skills:
            core_required = [normalize_skill(s) for s in request.custom_benchmark_skills]
            secondary_required = []
            bonus_required = []
            category_weights = {}
        else:
            benchmark = get_benchmark_role(request.target_role)
            if not benchmark:
                # Fallback to full stack developer if unmatched
                benchmark = BENCHMARK_ROLES["full_stack_developer"]
                
            role_id = benchmark["role_id"]
            target_role_name = benchmark["role_name"]
            core_required = benchmark.get("core_skills", [])
            secondary_required = benchmark.get("secondary_skills", [])
            bonus_required = benchmark.get("bonus_skills", [])
            category_weights = benchmark.get("category_weights", {})

        # Prepare evaluation list: (skill_name, importance, weight)
        eval_items: List[Tuple[str, str, float]] = []
        for s in core_required:
            eval_items.append((s, "Critical", 1.0))
        for s in secondary_required:
            eval_items.append((s, "Secondary", 0.6))
        for s in bonus_required:
            eval_items.append((s, "Bonus", 0.3))

        matched_skills: List[SkillDetail] = []
        missing_critical: List[SkillDetail] = []
        missing_secondary: List[SkillDetail] = []
        matched_student_skills: Set[str] = set()

        total_weight_sum = 0.0
        earned_weight_sum = 0.0
        category_stats: Dict[str, Dict[str, int]] = {}

        # Evaluate each required skill
        for req_skill, importance, weight in eval_items:
            canonical_req = normalize_skill(req_skill)
            category = categorize_skill(canonical_req)
            
            if category not in category_stats:
                category_stats[category] = {"matched": 0, "total": 0}
            
            if importance in ("Critical", "Secondary"):
                category_stats[category]["total"] += 1
                total_weight_sum += weight

            # 1. Exact Match Check
            if canonical_req in student_canonical_set:
                matched_student_skills.add(canonical_req)
                earned_weight_sum += weight
                if importance in ("Critical", "Secondary"):
                    category_stats[category]["matched"] += 1
                matched_skills.append(
                    SkillDetail(
                        skill_name=canonical_req,
                        category=category,
                        importance=importance,
                        weight=weight,
                        status="Matched",
                        similarity_score=1.0,
                        matched_with=canonical_req
                    )
                )
                continue

            # 2. Semantic Similarity Check
            best_match = None
            best_sim = 0.0
            for student_skill in student_canonical_set:
                sim = self._compute_semantic_similarity(canonical_req, student_skill)
                if sim > best_sim:
                    best_sim = sim
                    best_match = student_skill

            if best_sim >= 0.75 and best_match:
                matched_student_skills.add(best_match)
                earned_credit = weight * best_sim
                earned_weight_sum += earned_credit
                if importance in ("Critical", "Secondary"):
                    category_stats[category]["matched"] += 1
                matched_skills.append(
                    SkillDetail(
                        skill_name=canonical_req,
                        category=category,
                        importance=importance,
                        weight=weight,
                        status="Matched",
                        similarity_score=round(best_sim, 2),
                        matched_with=best_match
                    )
                )
            else:
                # Skill is missing
                detail = SkillDetail(
                    skill_name=canonical_req,
                    category=category,
                    importance=importance,
                    weight=weight,
                    status="Missing",
                    similarity_score=round(best_sim, 2) if best_sim > 0.3 else 0.0,
                    matched_with=best_match if best_sim > 0.3 else None
                )
                if importance == "Critical":
                    missing_critical.append(detail)
                elif importance == "Secondary":
                    missing_secondary.append(detail)


        # Identify student bonus/unmatched strengths
        bonus_strengths = [
            s for s in student_canonical_set if s not in matched_student_skills
        ]

        # Calculate Placement Readiness Score (0 - 100%)
        if total_weight_sum > 0:
            raw_score = (earned_weight_sum / total_weight_sum) * 100.0
        else:
            raw_score = 0.0

        # Adjust for experience level
        if request.experience_level == "Mid Level":
            raw_score = max(0.0, raw_score * 0.9)
        elif request.experience_level == "Senior":
            raw_score = max(0.0, raw_score * 0.8)

        placement_readiness_score = round(min(100.0, max(0.0, raw_score)), 1)

        # Determine Readiness Tier
        if placement_readiness_score >= 80.0:
            readiness_level = "Job Ready (Placement Ready)"
        elif placement_readiness_score >= 60.0:
            readiness_level = "Near Ready (Minor Upskilling Needed)"
        elif placement_readiness_score >= 40.0:
            readiness_level = "Needs Upskilling (Action Plan Recommended)"
        else:
            readiness_level = "Foundational (Comprehensive Training Needed)"

        # Prepare Category Breakdown
        category_breakdown: List[CategoryScore] = []
        for cat, stats in sorted(category_stats.items()):
            score_pct = round((stats["matched"] / stats["total"]) * 100.0, 1) if stats["total"] > 0 else 0.0
            category_breakdown.append(
                CategoryScore(
                    category=cat,
                    matched_count=stats["matched"],
                    total_count=stats["total"],
                    score_percentage=score_pct
                )
            )

        # Generate Course Recommendations for Missing Skills
        all_missing_names = [s.skill_name for s in missing_critical] + [s.skill_name for s in missing_secondary]
        recommended_courses = self.course_recommender.recommend_for_skills(
            missing_skills=all_missing_names[:6], max_per_skill=1
        )

        # Generate Hands-on Project Recommendations
        recommended_projects = self.project_recommender.recommend_for_gaps(
            missing_skills=all_missing_names,
            target_role_id=role_id,
            max_projects=3
        )

        # Generate Action Plan
        action_plan = self._generate_action_plan(
            student_name=request.student_name or "Student",
            target_role=target_role_name,
            score=placement_readiness_score,
            missing_critical=missing_critical,
            recommended_projects=recommended_projects
        )

        return SkillGapResponse(
            student_name=request.student_name or "Student",
            target_role=target_role_name,
            placement_readiness_score=placement_readiness_score,
            readiness_level=readiness_level,
            total_benchmark_skills=len(eval_items),
            total_student_skills=len(student_canonical_set),
            matched_skills_count=len(matched_skills),
            missing_skills_count=len(missing_critical) + len(missing_secondary),
            matched_skills=matched_skills,
            missing_critical_skills=missing_critical,
            missing_secondary_skills=missing_secondary,
            strengths_or_bonus_skills=bonus_strengths,
            category_breakdown=category_breakdown,
            recommended_courses=recommended_courses,
            recommended_projects=recommended_projects,
            action_plan=action_plan,
            metadata={
                "experience_level": request.experience_level,
                "target_company": request.target_company,
                "engine_version": "EduBridge-AI-SkillGap-v1.0"
            }
        )

    def analyze_from_job_description(self, request: JobDescriptionGapRequest) -> SkillGapResponse:
        """
        Extracts required skills from a raw Job Description text and analyzes gaps.
        """
        extracted_skills = extract_skills_from_text(request.job_description_text)
        
        if not extracted_skills:
            extracted_skills = ["Python", "SQL", "Git", "Problem Solving", "REST APIs"]

        gap_req = SkillGapRequest(
            student_name=request.student_name,
            student_skills=request.student_skills,
            target_role=request.target_role or "Custom Job Posting",
            custom_benchmark_skills=extracted_skills
        )
        return self.analyze(gap_req)

    def _generate_action_plan(
        self,
        student_name: str,
        target_role: str,
        score: float,
        missing_critical: List[SkillDetail],
        recommended_projects: List[ProjectRecommendation]
    ) -> List[str]:
        """Creates personalized, step-by-step roadmap action items."""
        plan = []
        if score >= 80.0:
            plan.append(f"✅ Excellent preparation! You are currently at {score}% readiness for {target_role}.")
            plan.append("🎯 Schedule mock technical interviews and leverage the Mentor Match Engine to connect with alumni at target companies.")
            plan.append("💼 Polish your resume and portfolio project links to start applying for open opportunities.")
        else:
            plan.append(f"📊 Your current Placement Readiness Score is {score}% for {target_role}.")
            
            if missing_critical:
                crit_names = ", ".join([s.skill_name for s in missing_critical[:3]])
                plan.append(f"🚀 High Priority: Master top critical missing skills first: **{crit_names}** using the recommended courses below.")
            
            if recommended_projects:
                proj_title = recommended_projects[0].title
                plan.append(f"🛠️ Hands-On Skilling: Complete project **'{proj_title}'** to demonstrate practical application of missing skills on GitHub.")
                
            plan.append("🤝 Connect with an Alumni Mentor in your target domain via EduBridge Mentor Match for feedback and code review.")
            plan.append("📈 Re-run Skill Gap Analyzer after completing projects to watch your Readiness Score rise.")

        return plan
