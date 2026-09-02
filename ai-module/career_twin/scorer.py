"""
Career Score Engine
===================
Computes a weighted composite Career Score from four signals:
  1. Skill Match Score     (40%)
  2. Semantic Similarity   (25%)
  3. Experience Relevance  (20%)
  4. Education Bonus       (15%)
"""

class CareerScorer:

    # Scoring weights (must sum to 1.0)
    WEIGHT_SKILL_MATCH   = 0.40
    WEIGHT_SEMANTIC      = 0.25
    WEIGHT_EXPERIENCE    = 0.20
    WEIGHT_EDUCATION     = 0.15

    # Education level numeric mapping
    EDUCATION_SCORES = {
        "phd":       1.0,
        "masters":   0.85,
        "bachelors": 0.70,
        "diploma":   0.50,
        "unknown":   0.40,
    }

    @staticmethod
    def _skill_match_score(matched: list, required_total: int) -> float:
        """Percentage of required skills that the candidate possesses."""
        if required_total == 0:
            return 0.0
        return round(len(matched) / required_total, 4)

    @staticmethod
    def _experience_score(candidate_years: float, required_years: float) -> float:
        """
        Scores experience:
          - Full score if candidate meets/exceeds requirement.
          - Partial credit down to zero.
          - Slight bonus (capped at 1.0) for over-qualification.
        """
        if required_years <= 0:
            return 1.0  # no experience stated → neutral
        ratio = candidate_years / required_years
        if ratio >= 1.0:
            return min(1.0, 0.90 + 0.10 * min(ratio - 1.0, 1.0))  # slight overqualification bonus
        return round(ratio, 4)

    @classmethod
    def _education_score(cls, candidate_education: list) -> float:
        """Returns the highest education score for the candidate."""
        if not candidate_education:
            return cls.EDUCATION_SCORES["unknown"]
        return max(cls.EDUCATION_SCORES.get(ed, 0.40) for ed in candidate_education)

    @classmethod
    def compute(
        cls,
        matched_skills: list,
        required_skills: list,
        semantic_similarity: float,
        candidate_years: float,
        required_years: float,
        candidate_education: list,
    ) -> dict:
        """
        Computes a full Career Score breakdown.

        Returns:
            dict with individual component scores and final career_score (0-100).
        """
        skill_score   = cls._skill_match_score(matched_skills, len(required_skills))
        exp_score     = cls._experience_score(candidate_years, required_years)
        edu_score     = cls._education_score(candidate_education)

        # Weighted composite (all sub-scores are 0-1)
        raw = (
            skill_score        * cls.WEIGHT_SKILL_MATCH +
            semantic_similarity * cls.WEIGHT_SEMANTIC    +
            exp_score          * cls.WEIGHT_EXPERIENCE   +
            edu_score          * cls.WEIGHT_EDUCATION
        )

        career_score = round(raw * 100, 2)  # convert to 0-100 scale

        # Qualitative tier label
        if career_score >= 85:
            tier = "Excellent Match 🌟"
        elif career_score >= 70:
            tier = "Strong Match ✅"
        elif career_score >= 55:
            tier = "Moderate Match 🔶"
        elif career_score >= 40:
            tier = "Weak Match ⚠️"
        else:
            tier = "Poor Match ❌"

        return {
            "career_score":       career_score,
            "tier":               tier,
            "skill_score":        round(skill_score * 100, 2),
            "semantic_score":     round(semantic_similarity * 100, 2),
            "experience_score":   round(exp_score * 100, 2),
            "education_score":    round(edu_score * 100, 2),
        }
