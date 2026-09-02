from typing import Dict, Any, List
from app.models.profile import CareerProfile
from app.models.result import CareerGPSResult, UserState, TargetInfo, ReadinessInfo
from app.knowledge.career_database import career_db
from app.engine.profile_analyzer import profile_analyzer
from app.engine.career_matcher import career_matcher
from app.engine.skill_gap_analyzer import skill_gap_analyzer
from app.engine.readiness_scorer import readiness_scorer
from app.engine.roadmap_planner import roadmap_planner
from app.engine.recommendation_engine import recommendation_engine
from app.ai.llm_service import get_llm_service
from app.ai.output_parser import OutputParser
from app.ai.prompts import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE

class CareerGPSEngine:
    def __init__(self):
        self.llm_service = get_llm_service()
        self.parser = OutputParser(self.llm_service)

    def generate(self, profile: CareerProfile) -> CareerGPSResult:
        # 1. Profile analysis & Skill extraction
        analysis = profile_analyzer.analyze_profile(profile)
        effective_skills = analysis["effective_skills"]
        career_level = analysis["career_level"]
        total_exp_months = analysis["total_experience_months"]

        # 2. Match and resolve target career path
        target_career_name = profile.target_career
        target_career = career_db.get_career_by_title(target_career_name)
        if not target_career:
            # Fallback to listing a generic profile or raising error if database empty
            careers_list = career_db.list_careers()
            if careers_list:
                target_career = careers_list[0]
                print(f"Warning: Target career '{target_career_name}' not found. Defaulting to '{target_career.title}' from database.")
            else:
                raise ValueError("Career database is empty. Cannot match target career.")

        # 3. Deterministic Skill Gap Analysis
        gaps = skill_gap_analyzer.analyze_gaps(
            user_skills=effective_skills,
            target_career=target_career,
            user_interests=profile.interests or []
        )

        # 4. Deterministic Readiness Scoring
        readiness = readiness_scorer.calculate_readiness(
            profile=profile,
            target_career=target_career,
            effective_skills=effective_skills,
            total_experience_months=total_exp_months
        )

        # 5. Roadmap Generation
        roadmap = roadmap_planner.generate_roadmap(
            profile=profile,
            target_career=target_career,
            skill_gaps=gaps
        )

        # 6. Recommendation Calculations
        recs = recommendation_engine.generate_recommendations(
            profile=profile,
            skill_gaps=gaps,
            roadmap=roadmap
        )

        # 7. Confidence Score Calculation
        # Confidence = 0.4 * EvidenceRatio + 0.3 * ProfileCompleteness + 0.3 * CareerMatchScore
        # Calculate Evidence Ratio: fraction of user's skills that have evidence
        total_skills = len(profile.skills)
        skills_with_evidence = sum(1 for s in profile.skills if s.evidence)
        evidence_ratio = (skills_with_evidence / total_skills) if total_skills > 0 else 0.0
        
        # Calculate Profile Completeness
        completeness_checks = [
            1 if profile.education else 0,
            1 if profile.projects else 0,
            1 if profile.experience else 0,
            1 if profile.certifications else 0
        ]
        profile_completeness = sum(completeness_checks) / len(completeness_checks)
        
        # Calculate Career Match Score (from CareerMatcher)
        all_matches = career_matcher.match_careers(
            user_skills=effective_skills,
            user_interests=profile.interests or [],
            current_role=profile.current_role
        )
        # Find match score for target career
        match_score = 0.5 # default moderate baseline
        for m in all_matches:
            if m["career_id"] == target_career.id:
                match_score = m["match_score"]
                break
                
        confidence = (evidence_ratio * 0.4) + (profile_completeness * 0.3) + (match_score * 0.3)
        # Bounded between 0.3 and 0.98 for realistic limits
        confidence = max(0.3, min(0.98, confidence))

        # 8. LLM Personalization and Explanation Synthesis
        # Extract strong/weak/missing skill sets for prompt
        strong_skills = [g.skill for g in gaps if g.gap == 0]
        weak_skills = [f"{g.skill} (Gap: {g.gap})" for g in gaps if g.gap > 0 and g.current_level > 0]
        missing_skills = [g.skill for g in gaps if g.current_level == 0]
        
        projects_names = [p["name"] for p in recs["recommended_projects"]]
        
        roadmap_outline = "\n".join([
            f"Phase {ph.phase}: {ph.title} ({ph.duration_weeks} weeks) - Skills: {', '.join(ph.skills)}"
            for ph in roadmap.phases
        ])

        prompt_kwargs = {
            "current_role": profile.current_role,
            "education": f"{profile.education.degree} in {profile.education.field}" if profile.education else "None",
            "target_career": target_career.title,
            "target_duration_months": profile.target_duration_months,
            "readiness_score": readiness["score"],
            "confidence_score": confidence,
            "strong_skills": str(strong_skills),
            "weak_skills": str(weak_skills),
            "missing_skills": str(missing_skills),
            "recommended_projects": str(projects_names),
            "roadmap_outline": roadmap_outline
        }

        try:
            llm_result = self.llm_service.generate_personalization(prompt_kwargs)
        except Exception as e:
            print(f"LLM synthesis failed: {e}. Falling back to deterministic output.")
            # Format user prompt manually to pass to fallback if needed
            user_prompt = USER_PROMPT_TEMPLATE.format(**prompt_kwargs)
            llm_result = self.parser.get_deterministic_fallback(user_prompt)

        # 9. Build final result mapping
        # Merge LLM-personalized explanation and next action
        return CareerGPSResult(
            user_state=UserState(
                current_role=profile.current_role,
                career_level=career_level
            ),
            target=TargetInfo(
                career=target_career.title,
                timeline_months=profile.target_duration_months
            ),
            readiness=ReadinessInfo(
                score=readiness["score"],
                details=readiness["details"],
                explanation=readiness["explanation"]
            ),
            skill_gaps=gaps,
            recommended_projects=recs["recommended_projects"],
            roadmap=roadmap,
            personalization=llm_result,
            confidence=confidence
        )

# Singleton instance
career_gps = CareerGPSEngine()
