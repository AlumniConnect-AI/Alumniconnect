"""
Career Twin Engine — Main Orchestrator
=======================================
Public API surface for the entire AI module.

Usage:
    from career_twin.engine import CareerTwinEngine

    result = CareerTwinEngine.analyze(
        profile_text = "...",   # resume / profile text
        jd_text      = "...",   # job description text
        required_experience_years = 2.0,  # optional, defaults to 0
    )
"""
import json
from .nlp_parser    import NLPParser
from .matcher       import SemanticMatcher
from .scorer        import CareerScorer
from .skill_profiler import SkillProfiler


class CareerTwinEngine:
    """Top-level orchestrator. Stateless: all methods are class/static methods."""

    _matcher = SemanticMatcher()

    @classmethod
    def analyze(
        cls,
        profile_text: str,
        jd_text: str,
        required_experience_years: float = 0.0,
    ) -> dict:
        """
        Full pipeline: NLP → Matching → Scoring → Profiling.

        Args:
            profile_text              : Full candidate resume / profile text
            jd_text                   : Full job description text
            required_experience_years : Years of experience stated in the JD

        Returns:
            dict with keys:
              - parsed_profile  : extracted candidate metadata
              - parsed_jd       : extracted JD metadata
              - career_score    : scoring breakdown (0-100 composite)
              - skill_profile   : skills analysis
        """
        # ── Step 1: Parse inputs ──────────────────────────────────────
        parsed_profile = NLPParser.parse_profile(profile_text)
        parsed_jd      = NLPParser.parse_profile(jd_text)

        # ── Step 2: Build text representations ───────────────────────
        # For semantic similarity we use the raw texts
        semantic_sim = cls._matcher.calculate_similarity(profile_text, jd_text)

        # ── Step 3: Skill overlap analysis ───────────────────────────
        overlap = SemanticMatcher.get_token_overlap(
            parsed_profile["tech_skills"],
            parsed_jd["tech_skills"],
        )

        # Determine effective required experience: if 0 provided, auto-detect from parsed JD
        effective_req_exp = required_experience_years
        if effective_req_exp <= 0.0 and parsed_jd["experience_years"] > 0.0:
            effective_req_exp = parsed_jd["experience_years"]

        # ── Step 4: Score computation ─────────────────────────────────
        score_breakdown = CareerScorer.compute(
            matched_skills       = overlap["matched"],
            required_skills      = parsed_jd["tech_skills"],
            semantic_similarity  = semantic_sim,
            candidate_years      = parsed_profile["experience_years"],
            required_years       = effective_req_exp,
            candidate_education  = parsed_profile["education"],
        )

        # ── Step 5: Skill profile generation ─────────────────────────
        skill_profile = SkillProfiler.generate_profile(
            candidate_skills = parsed_profile["tech_skills"],
            required_skills  = parsed_jd["tech_skills"],
            matched_skills   = overlap["matched"],
            missing_skills   = overlap["missing"],
            extra_skills     = overlap["extra"],
        )

        # ── Final result structure ────────────────────────────────────
        return {
            "parsed_profile": parsed_profile,
            "parsed_jd":      parsed_jd,
            "career_score":   score_breakdown,
            "skill_profile":  skill_profile,
        }

    @classmethod
    def analyze_and_format(cls, profile_text: str, jd_text: str,
                           required_experience_years: float = 0.0) -> str:
        """Convenience method that returns results as a pretty-printed JSON string."""
        result = cls.analyze(profile_text, jd_text, required_experience_years)
        return json.dumps(result, indent=2, ensure_ascii=False)
