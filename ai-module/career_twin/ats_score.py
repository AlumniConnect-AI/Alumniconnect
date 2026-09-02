class ATSScoreEngine:
    """Calculates an ATS (Applicant Tracking System) compatibility score (0-100)."""

    @staticmethod
    def calculate_ats_score(
        skill_match_ratio: float,
        semantic_sim: float,
        exp_ratio: float,
        has_contact_info: bool,
        has_projects: bool,
        has_education: bool
    ) -> dict:
        """
        Computes weighted ATS score out of 100 based on:
        - Skills match (35%)
        - Semantic similarity (25%)
        - Experience match (20%)
        - Resume formatting & section completeness (20%)
        """
        skill_score = skill_match_ratio * 35.0
        semantic_score = semantic_sim * 25.0
        exp_score = min(1.0, exp_ratio) * 20.0

        completeness_score = 0.0
        if has_contact_info: completeness_score += 8.0
        if has_projects: completeness_score += 6.0
        if has_education: completeness_score += 6.0

        total_ats = round(skill_score + semantic_score + exp_score + completeness_score, 1)

        recommendations = []
        if skill_match_ratio < 0.6:
            recommendations.append("Add missing job-specific technical keywords to pass initial ATS screening filters.")
        if exp_ratio < 0.8:
            recommendations.append("Quantify your project outcomes & achievements with measurable metrics (e.g. % improvement).")
        if not has_projects:
            recommendations.append("Add a dedicated Projects section detailing technical stack used.")
        if total_ats >= 80:
            recommendations.append("High ATS Compatibility! Resume is well optimized for automated screening.")

        return {
            "ats_score": total_ats,
            "skill_match_contrib": round(skill_score, 1),
            "semantic_contrib": round(semantic_score, 1),
            "experience_contrib": round(exp_score, 1),
            "formatting_contrib": round(completeness_score, 1),
            "ats_recommendations": recommendations
        }
