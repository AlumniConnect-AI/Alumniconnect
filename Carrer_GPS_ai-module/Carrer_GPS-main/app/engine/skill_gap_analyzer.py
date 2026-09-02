from typing import Dict, List, Any
from app.models.skill import SkillGap
from app.models.career import CareerDetail
from app.knowledge.skill_database import skill_db

class SkillGapAnalyzer:
    def analyze_gaps(self, user_skills: Dict[str, Dict[str, Any]], target_career: CareerDetail, user_interests: List[str]) -> List[SkillGap]:
        gaps: List[SkillGap] = []
        
        # Combine required and preferred skills
        target_skills = {}
        for s, lvl in target_career.required_skills.items():
            target_skills[s] = {"level": lvl, "importance": 2.0} # higher weight for required
        for s, lvl in target_career.preferred_skills.items():
            if s not in target_skills:
                target_skills[s] = {"level": lvl, "importance": 1.0} # lower weight for preferred

        # Identify all user interests for goal relevance weighting
        interests_set = {skill_db.normalize_skill_name(interest) for interest in user_interests}

        for skill_name, target_info in target_skills.items():
            req_level = target_info["level"]
            importance = target_info["importance"]
            
            user_info = user_skills.get(skill_name, {})
            current_level = user_info.get("level", 0)
            evidence = user_info.get("evidence", [])
            
            gap = max(0, req_level - current_level)
            
            # Determine Category
            if current_level == 0:
                category = "MISSING"
            elif gap > 0:
                if current_level <= 1:
                    category = "WEAK"
                else:
                    category = "DEVELOPING"
            else:
                if current_level >= 4:
                    category = "STRONG"
                else:
                    category = "ADEQUATE"

            # Calculate Priority Score:
            # Priority = Career Importance * Skill Gap * Dependency Importance * User Goal Relevance
            if gap == 0:
                priority_score = 0.0
                priority_label = "NONE"
            else:
                # 1. Dependency Importance: check how many other target skills depend on this one.
                # If target skills contains keys that have this skill as a prerequisite, we bump dependency importance.
                dep_count = 0
                for other_skill in target_skills.keys():
                    if other_skill != skill_name:
                        prereqs = skill_db.get_prerequisites(other_skill)
                        if skill_name in prereqs:
                            dep_count += 1
                dependency_importance = 1.0 + (dep_count * 0.5)
                
                # 2. User Goal Relevance
                user_goal_relevance = 1.2 if skill_name in interests_set else 1.0
                
                # 3. Calculate score
                priority_score = importance * gap * dependency_importance * user_goal_relevance
                
                # Assign labels
                if priority_score >= 8.0:
                    priority_label = "HIGH"
                elif priority_score >= 4.0:
                    priority_label = "MEDIUM"
                else:
                    priority_label = "LOW"

            # Build explainability reason
            if category == "MISSING":
                reason = f"{skill_name} is required for {target_career.title} but is currently missing from your profile with no evidence."
            elif category == "WEAK":
                reason = f"Your proficiency in {skill_name} is weak (level {current_level}/{req_level}) relative to the target requirements."
            elif category == "DEVELOPING":
                reason = f"Your {skill_name} skill is developing (level {current_level}/{req_level}) but needs improvement to meet production standards."
            elif category == "STRONG":
                reason = f"You possess a strong skill level in {skill_name} ({current_level}/{req_level}) that exceeds target expectations."
            else:
                reason = f"Your skill level in {skill_name} ({current_level}/{req_level}) is adequate for the target role."

            if gap > 0 and priority_label == "HIGH":
                reason += f" This is a HIGH PRIORITY gap because it is a key prerequisite or has high career importance."

            gaps.append(SkillGap(
                skill=skill_name,
                current_level=current_level,
                required_level=req_level,
                gap=gap,
                priority_score=priority_score,
                priority=priority_label,
                evidence=evidence,
                reason=reason
            ))
            
        # Sort gaps by priority score descending
        gaps.sort(key=lambda x: x.priority_score, reverse=True)
        return gaps

# Singleton instance
skill_gap_analyzer = SkillGapAnalyzer()
