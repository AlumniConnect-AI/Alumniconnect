from typing import Dict, Any, List
from app.models.profile import CareerProfile
from app.models.career import CareerDetail
from app.core.constants import (
    WEIGHT_SKILL, WEIGHT_PROJECT, WEIGHT_EXPERIENCE,
    WEIGHT_EDUCATION, WEIGHT_CERTIFICATION, WEIGHT_INTEREST
)
from app.utils.scoring import (
    calculate_skill_match_score,
    calculate_project_match_score,
    calculate_experience_match_score,
    calculate_education_match_score
)
from app.ai.embedding_service import embedding_service
from app.utils.scoring import cosine_similarity

class ReadinessScorer:
    def calculate_readiness(
        self,
        profile: CareerProfile,
        target_career: CareerDetail,
        effective_skills: Dict[str, Dict[str, Any]],
        total_experience_months: float
    ) -> Dict[str, Any]:
        # 1. Skill Match Score (40%)
        user_skill_levels = {name: info["level"] for name, info in effective_skills.items()}
        skill_match = calculate_skill_match_score(
            user_skills=user_skill_levels,
            required_skills=target_career.required_skills,
            preferred_skills=target_career.preferred_skills
        ) * 100
        
        # 2. Project Match Score (20%)
        user_projects_list = []
        for p in (profile.projects or []):
            user_projects_list.append({
                "name": p.name,
                "description": p.description,
                "technologies": p.technologies
            })
        required_skills_list = list(target_career.required_skills.keys())
        project_match = calculate_project_match_score(
            user_projects=user_projects_list,
            required_skills=required_skills_list
        ) * 100
        
        # 3. Experience Match Score (15%)
        experience_match = calculate_experience_match_score(
            total_experience_months=total_experience_months,
            target_experience_years=target_career.typical_experience_years
        ) * 100
        
        # 4. Education Match Score (10%)
        education_field = profile.education.field if profile.education else ""
        education_match = calculate_education_match_score(
            user_field=education_field,
            education_relevance=target_career.education_relevance
        ) * 100
        
        # 5. Certification Match Score (5%)
        # Each certification adds 50 points, capped at 100
        num_certs = len(profile.certifications) if profile.certifications else 0
        certification_match = min(100.0, num_certs * 50.0)
        
        # 6. Interest Match Score (10%)
        # Computed using semantic similarity between interests and target career description
        if profile.interests:
            interests_text = ", ".join(profile.interests)
            interests_vector = embedding_service.get_embedding(interests_text)
            
            career_text = f"{target_career.title}: {target_career.description}"
            career_vector = embedding_service.get_embedding(career_text)
            
            sim = cosine_similarity(interests_vector, career_vector)
            # Scale cosine similarity (-1 to 1) to (0 to 100)
            interest_match = max(0.0, min(100.0, (sim + 1.0) / 2.0 * 100))
        else:
            interest_match = 40.0 # low default baseline if no interests declared
            
        # Compile Weighted Score
        weighted_score = (
            (skill_match * WEIGHT_SKILL) +
            (project_match * WEIGHT_PROJECT) +
            (experience_match * WEIGHT_EXPERIENCE) +
            (education_match * WEIGHT_EDUCATION) +
            (certification_match * WEIGHT_CERTIFICATION) +
            (interest_match * WEIGHT_INTEREST)
        )
        
        final_score = round(weighted_score)
        
        # Compile explaining statement
        explanation_parts = []
        explanation_parts.append(f"Skill Match is at {skill_match:.0f}% based on target required skills.")
        if project_match > 0:
            explanation_parts.append(f"Projects cover {project_match:.0f}% of required tech stack competencies.")
        else:
            explanation_parts.append("No projects in your profile address the required skills.")
            
        explanation_parts.append(
            f"Experience is at {experience_match:.0f}% of typical target requirements ({target_career.typical_experience_years} years)."
        )
        
        explanation = " ".join(explanation_parts)
        
        return {
            "score": final_score,
            "details": {
                "skill_match": round(skill_match),
                "project_match": round(project_match),
                "experience_match": round(experience_match),
                "education_match": round(education_match),
                "certification_match": round(certification_match),
                "interest_match": int(round(interest_match))
            },
            "explanation": explanation
        }

# Singleton instance
readiness_scorer = ReadinessScorer()
