from typing import List, Dict, Any
from app.models.profile import CareerProfile
from app.models.skill import SkillGap
from app.models.roadmap import CareerRoadmap
from app.knowledge.learning_database import learning_db

class RecommendationEngine:
    def generate_recommendations(
        self,
        profile: CareerProfile,
        skill_gaps: List[SkillGap],
        roadmap: CareerRoadmap
    ) -> Dict[str, Any]:
        # 1. Fetch recommended projects that address current gaps
        gap_skill_names = [gap.skill for gap in skill_gaps if gap.gap > 0]
        
        raw_recommendations = learning_db.get_projects_for_skills(gap_skill_names)
        
        # Format the recommended projects for response
        recommended_projects = []
        for proj in raw_recommendations[:3]: # Cap at top 3 projects
            # Build deterministic explanation
            overlap_skills = proj.get("matched_skills", [])
            explanation = (
                f"This project is recommended because it allows you to demonstrate hands-on application of "
                f"{', '.join(overlap_skills)}, which are identified gaps in your target career profile."
            )
            
            recommended_projects.append({
                "name": proj["name"],
                "description": proj["description"],
                "difficulty": proj["difficulty"],
                "estimated_hours": proj["estimated_hours"],
                "skills_addressed": overlap_skills,
                "milestones": proj.get("milestones", []),
                "explanation": explanation
            })

        # 2. Formulate Next Best Action
        next_best_action = ""
        first_phase = roadmap.phases[0] if roadmap.phases else None
        
        if first_phase and first_phase.skills:
            primary_gap_skill = first_phase.skills[0]
            
            # Check if user has an existing project we can attach this to
            user_project_name = None
            if profile.projects:
                user_project_name = profile.projects[0].name
                
            if primary_gap_skill == "Testing" and user_project_name:
                next_best_action = (
                    f"Complete {primary_gap_skill} by writing Unit and Widget tests "
                    f"for your existing {user_project_name} codebase to close this production gap."
                )
            elif primary_gap_skill == "State Management" and user_project_name:
                next_best_action = (
                    f"Refactor the state architecture of your {user_project_name} project using Riverpod or BLoC "
                    f"to separate the UI and business logic layers."
                )
            else:
                # Fallback to starting the phase project
                proj_name = first_phase.project or "a new sandbox repo"
                next_best_action = (
                    f"Initialize the '{proj_name}' project repository and complete the foundational "
                    f"concept studies for {primary_gap_skill}."
                )
        else:
            next_best_action = "Review your target career requirements and run a gap analysis on advanced topics."

        return {
            "recommended_projects": recommended_projects,
            "next_best_action": next_best_action
        }

# Singleton instance
recommendation_engine = RecommendationEngine()
