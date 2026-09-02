import numpy as np
from typing import Dict, List, Any

def cosine_similarity(v1: np.ndarray, v2: np.ndarray) -> float:
    # Computes cosine similarity between two vectors
    if v1 is None or v2 is None:
        return 0.0
    dot_prod = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0
    return float(dot_prod / (norm_v1 * norm_v2))

def calculate_skill_match_score(user_skills: Dict[str, int], required_skills: Dict[str, int], preferred_skills: Dict[str, int]) -> float:
    # Calculates a score based on how close the user's skills are to required/preferred
    if not required_skills:
        return 1.0
        
    required_scores = []
    for req_skill, req_level in required_skills.items():
        user_level = user_skills.get(req_skill, 0)
        if user_level >= req_level:
            required_scores.append(1.0)
        else:
            required_scores.append(user_level / req_level)
            
    # Preferred skills (bonus weighting, caps at 100%)
    preferred_scores = []
    for pref_skill, pref_level in preferred_skills.items():
        user_level = user_skills.get(pref_skill, 0)
        if user_level >= pref_level:
            preferred_scores.append(1.0)
        else:
            preferred_scores.append(user_level / pref_level)
            
    avg_required = sum(required_scores) / len(required_scores) if required_scores else 0.0
    
    if preferred_scores:
        avg_preferred = sum(preferred_scores) / len(preferred_scores)
        # 80% required skills, 20% preferred skills
        total_score = (avg_required * 0.8) + (avg_preferred * 0.2)
    else:
        total_score = avg_required
        
    return min(1.0, total_score)

def calculate_project_match_score(user_projects: List[Dict[str, Any]], required_skills: List[str]) -> float:
    # Computes matching percentage of user projects covering required skills
    if not required_skills or not user_projects:
        return 0.0
        
    covered_skills = set()
    for project in user_projects:
        techs = project.get("technologies", [])
        for tech in techs:
            covered_skills.add(tech)
            
    req_set = set(required_skills)
    intersection = req_set.intersection(covered_skills)
    return len(intersection) / len(req_set)

def calculate_experience_match_score(total_experience_months: float, target_experience_years: int) -> float:
    # Proportional score against target experience years
    if target_experience_years <= 0:
        return 1.0
        
    target_months = target_experience_years * 12
    if total_experience_months >= target_months:
        return 1.0
        
    return total_experience_months / target_months

def calculate_education_match_score(user_field: str, education_relevance: Dict[str, float]) -> float:
    # Score education field based on relevance dictionary from career knowledge base
    if not education_relevance:
        return 1.0
    if not user_field:
        return 0.2 # low baseline if no field provided
        
    user_field_lower = user_field.lower().strip()
    
    # Check exact match
    for field, rel in education_relevance.items():
        if field.lower() == user_field_lower:
            return rel
            
    # Check substring match
    for field, rel in education_relevance.items():
        if user_field_lower in field.lower() or field.lower() in user_field_lower:
            return rel
            
    # Check fallback value
    return education_relevance.get("Other", 0.4)
