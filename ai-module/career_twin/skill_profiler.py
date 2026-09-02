"""
Skill Profiler
==============
Generates a human-readable Skill Profile:
  • Matched skills (candidate ∩ job requirements)
  • Missing skills (job requirements ∖ candidate)
  • Skill strengths (skills the candidate has beyond the JD)
  • Suggested career roles based on skill fingerprint
  • Actionable recommendations
"""

# Role → required skill clusters mapping
ROLE_SKILL_MAP = {
    "Mobile App Developer (Flutter)": [
        "flutter", "dart", "firebase", "supabase", "git", "android"
    ],
    "Full-Stack Web Developer": [
        "html", "css", "javascript", "react", "nodejs", "mongodb", "git"
    ],
    "Backend Developer": [
        "python", "django", "postgresql", "mysql", "docker", "git"
    ],
    "Data Scientist": [
        "python", "machine learning", "scikit-learn", "pandas", "numpy", "git"
    ],
    "AI / ML Engineer": [
        "python", "machine learning", "deep learning", "tensorflow", "pytorch",
        "nlp", "scikit-learn", "git"
    ],
    "DevOps Engineer": [
        "docker", "kubernetes", "aws", "gcp", "git"
    ],
    "Cloud Architect": [
        "aws", "azure", "gcp", "docker", "kubernetes"
    ],
    "Frontend Developer": [
        "html", "css", "javascript", "react", "angular", "git"
    ],
    "Android Developer": [
        "android", "kotlin", "git", "firebase"
    ],
}

LEARNING_RESOURCES = {
    "flutter":          "https://docs.flutter.dev/get-started",
    "dart":             "https://dart.dev/guides",
    "machine learning": "https://www.coursera.org/learn/machine-learning",
    "deep learning":    "https://www.deeplearning.ai/",
    "nlp":              "https://www.nltk.org/",
    "docker":           "https://docs.docker.com/get-started/",
    "kubernetes":       "https://kubernetes.io/docs/tutorials/",
    "aws":              "https://aws.amazon.com/training/",
    "react":            "https://react.dev/learn",
    "nodejs":           "https://nodejs.org/en/learn",
    "git":              "https://git-scm.com/doc",
}


class SkillProfiler:

    @staticmethod
    def _match_roles(candidate_skills: list) -> list:
        """Returns top 3 career role matches ranked by skill overlap ratio."""
        candidate_set = set(s.lower() for s in candidate_skills)
        scored_roles = []
        for role, required in ROLE_SKILL_MAP.items():
            required_set = set(required)
            overlap = len(candidate_set.intersection(required_set))
            total   = len(required_set)
            ratio   = overlap / total if total > 0 else 0.0
            if ratio > 0:
                scored_roles.append((role, round(ratio * 100, 1)))

        # Sort descending and return top 3
        scored_roles.sort(key=lambda x: x[1], reverse=True)
        return [{"role": r, "match_percent": p} for r, p in scored_roles[:3]]

    @staticmethod
    def _get_resources(missing_skills: list) -> list:
        """Returns learning resources for missing skills."""
        resources = []
        for skill in missing_skills[:5]:  # top 5 missing skills
            url = LEARNING_RESOURCES.get(skill.lower())
            if url:
                resources.append({"skill": skill, "resource": url})
            else:
                resources.append({
                    "skill":    skill,
                    "resource": f"https://www.google.com/search?q=learn+{skill.replace(' ', '+')}"
                })
        return resources

    @classmethod
    def generate_profile(
        cls,
        candidate_skills: list,
        required_skills:  list,
        matched_skills:   list,
        missing_skills:   list,
        extra_skills:     list,
    ) -> dict:
        """
        Generates a complete Skill Profile dictionary.

        Args:
            candidate_skills : all tech skills from the candidate's profile
            required_skills  : skills extracted from the job description
            matched_skills   : intersection of above two
            missing_skills   : skills in JD but not in candidate profile
            extra_skills     : skills candidate has beyond what the JD requires

        Returns:
            dict with matched, missing, strengths, roles, recommendations
        """
        candidate_set = set(s.lower() for s in candidate_skills)
        required_set  = set(s.lower() for s in required_skills)

        coverage_pct = (
            round(len(matched_skills) / len(required_set) * 100, 1)
            if required_set else 0.0
        )

        # Classify strengths: skills candidate exceeds JD requirements
        strength_skills = sorted(extra_skills) if extra_skills else []

        # Role recommendations
        suggested_roles = cls._match_roles(list(candidate_set))

        # Learning resources for gaps
        resources = cls._get_resources(missing_skills)

        # Generate textual recommendations
        recommendations = []
        if missing_skills:
            top_missing = ", ".join(missing_skills[:3])
            recommendations.append(
                f"🎯 Focus on acquiring: {top_missing} — these are directly required by the role."
            )
        if coverage_pct < 60:
            recommendations.append(
                "📚 Your skill coverage is below 60%. Consider targeted upskilling before applying."
            )
        elif coverage_pct < 80:
            recommendations.append(
                "💪 You're close! A few more skills will make you a strong candidate."
            )
        else:
            recommendations.append(
                "🌟 Excellent skill coverage! Highlight your matched skills prominently in your resume."
            )
        if strength_skills:
            top_extra = ", ".join(strength_skills[:3])
            recommendations.append(
                f"✨ Highlight your extra strengths: {top_extra} — these differentiate you from other candidates."
            )

        return {
            "matched_skills":    sorted(matched_skills),
            "missing_skills":    sorted(missing_skills),
            "skill_strengths":   strength_skills,
            "skill_coverage_%":  coverage_pct,
            "suggested_roles":   suggested_roles,
            "learning_resources": resources,
            "recommendations":   recommendations,
        }
