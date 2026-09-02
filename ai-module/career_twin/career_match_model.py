from .similarity_engine import SemanticSimilarityEngine
from .ats_score import ATSScoreEngine

class CareerTwinModel:
    """Public Model Entrypoint for Career Twin AI Engine."""

    _sim_engine = SemanticSimilarityEngine()

    @classmethod
    def analyze(cls, profile: dict, jd_text: str, required_exp_years: float = 0.0) -> dict:
        """
        Runs complete Career Twin analysis.
        Input: profile dict from CandidateProfileBuilder (camelCase keys), jd_text string.
        Output: Career match dict with scores, ATS compatibility, skill overlap, recommendations.

        Handles both camelCase (from CandidateProfileBuilder) and snake_case profile formats.
        """
        # ── Extract skills — support both camelCase and snake_case keys ──────
        cand_skills_raw = (
            profile.get("allSkills")          # CandidateProfileBuilder output (camelCase)
            or profile.get("all_skills")      # Legacy snake_case
            or []
        )
        # Flatten if categorized dict was passed instead of a list
        if isinstance(cand_skills_raw, dict):
            flat = []
            for v in cand_skills_raw.values():
                if isinstance(v, list):
                    flat.extend(v)
            cand_skills_raw = flat

        # Normalize to lowercase strings for matching
        cand_skills = [str(s).lower().strip() for s in cand_skills_raw if s]

        # Also flatten from the skills category dict if allSkills is empty
        if not cand_skills:
            skills_dict = profile.get("skills") or {}
            if isinstance(skills_dict, dict):
                for v in skills_dict.values():
                    if isinstance(v, list):
                        cand_skills.extend([str(s).lower().strip() for s in v if s])

        # ── Extract experience (support camelCase + snake_case + flat float) ──
        cand_exp = 0.0
        total_exp = profile.get("totalExperienceYears") or profile.get("total_experience_years")
        if total_exp is not None:
            cand_exp = float(total_exp)
        else:
            # Try nested experience dict
            exp_dict = profile.get("experience") or {}
            if isinstance(exp_dict, dict):
                cand_exp = float(exp_dict.get("total_years") or exp_dict.get("totalYears") or 0.0)
            elif isinstance(exp_dict, (int, float)):
                cand_exp = float(exp_dict)

        # ── Extract raw text for semantic similarity ──────────────────────────
        cand_text = (
            profile.get("rawText")       # CandidateProfileBuilder (camelCase)
            or profile.get("raw_text")   # Legacy
            or " ".join(cand_skills)     # Fallback: join skills as proxy text
        )

        # ── Contact info — support both key formats ───────────────────────────
        personal_info = profile.get("personalInfo") or profile.get("personal_info") or {}
        contact_info = bool(personal_info.get("email") if isinstance(personal_info, dict) else False)

        # ── Education — support list (CandidateProfileBuilder) or dict ────────
        education_val = profile.get("education")
        has_education = False
        if isinstance(education_val, list):
            has_education = len(education_val) > 0
        elif isinstance(education_val, dict):
            has_education = bool(education_val.get("degrees") or education_val.get("list"))

        # ── Projects — support list or dict ───────────────────────────────────
        projects_val = profile.get("projects")
        has_projects = bool(projects_val) if projects_val else False

        # ── JD Skill Extraction ───────────────────────────────────────────────
        # Known technical keywords to always match from JD text
        known_tech_keywords = {
            "flutter", "dart", "python", "java", "react", "sql", "pl-sql",
            "aws", "docker", "firebase", "git", "mongodb", "postgresql",
            "fastapi", "django", "flask", "nodejs", "kubernetes", "tensorflow",
            "pytorch", "scikit-learn", "machine learning", "deep learning", "nlp",
            "html", "css", "javascript", "typescript", "angular", "vue", "express",
            "redis", "mysql", "sqlite", "supabase", "azure", "gcp", "github",
            "linux", "android", "ios", "kotlin", "swift", "power bi",
        }

        jd_lower = jd_text.lower()
        jd_words_set = set(jd_lower.replace(",", " ").replace(".", " ").split())
        jd_phrases = set()

        # Extract single-word skills
        for w in jd_words_set:
            cleaned = w.strip("()[]{}:;,.")
            if len(cleaned) > 2 and (cleaned in known_tech_keywords or cleaned in cand_skills):
                jd_phrases.add(cleaned)

        # Extract multi-word known skills from JD
        for keyword in known_tech_keywords:
            if " " in keyword and keyword in jd_lower:
                jd_phrases.add(keyword)

        jd_skills = sorted(jd_phrases)

        # ── 1. Semantic Similarity ─────────────────────────────────────────────
        semantic_sim = cls._sim_engine.calculate_similarity(cand_text, jd_text)

        # ── 2. Skill Overlap ───────────────────────────────────────────────────
        overlap = cls._sim_engine.get_skill_overlap(cand_skills, jd_skills)
        matched_skills = overlap["matched"]
        missing_skills = overlap["missing"]

        skill_match_ratio = len(matched_skills) / len(jd_skills) if jd_skills else 0.5

        # ── 3. Experience Match ────────────────────────────────────────────────
        effective_req_exp = max(required_exp_years, 0.5)
        exp_ratio = min(1.0, cand_exp / effective_req_exp) if effective_req_exp > 0 else 0.8

        # ── 4. ATS Score ───────────────────────────────────────────────────────
        ats_result = ATSScoreEngine.calculate_ats_score(
            skill_match_ratio=skill_match_ratio,
            semantic_sim=semantic_sim,
            exp_ratio=exp_ratio,
            has_contact_info=contact_info,
            has_projects=has_projects,
            has_education=has_education
        )

        # ── 5. Composite Match Score (0-100) ────────────────────────────────────
        # Weights: skills 40%, semantic 25%, experience 20%, baseline 15%
        composite_score = round(
            (skill_match_ratio * 40.0)
            + (semantic_sim * 25.0)
            + (exp_ratio * 20.0)
            + 15.0,
            1
        )
        # Cap at 100
        composite_score = min(100.0, composite_score)

        tier = (
            "Strong Match ✅" if composite_score >= 75 else
            ("Moderate Match 🔶" if composite_score >= 55 else "Weak Match ⚠️")
        )

        # ── 6. Debug diagnostics (logged only, not sent to client) ────────────
        print(
            f"[CareerTwin] skills={len(cand_skills)}, jd_skills={jd_skills}, "
            f"matched={matched_skills}, skill_ratio={skill_match_ratio:.2f}, "
            f"semantic={semantic_sim:.3f}, exp={cand_exp}/{effective_req_exp}, "
            f"score={composite_score}"
        )

        return {
            "matchScore": composite_score,
            "tier": tier,
            "matchedSkills": matched_skills,
            "missingSkills": missing_skills,
            "candidateSkills": cand_skills,
            "jdSkillsExtracted": jd_skills,
            "experienceMatch": round(exp_ratio * 100, 1),
            "atsScore": ats_result["ats_score"],
            "atsBreakdown": ats_result,
            "recommendations": ats_result["ats_recommendations"],
            "confidenceScore": 95.0
        }
