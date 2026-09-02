from typing import List, Dict, Any
from app.knowledge.career_database import career_db
from app.ai.embedding_service import embedding_service
from app.utils.scoring import cosine_similarity, calculate_skill_match_score

class CareerMatcher:
    def match_careers(self, user_skills: Dict[str, Dict[str, Any]], user_interests: List[str], current_role: str) -> List[Dict[str, Any]]:
        # 1. Prepare user text profile for embedding
        skills_str = ", ".join(user_skills.keys())
        interests_str = ", ".join(user_interests) if user_interests else "None"
        profile_text = f"Current Role: {current_role}. Skills: {skills_str}. Interests: {interests_str}."
        
        user_vector = embedding_service.get_embedding(profile_text)
        
        # Load career embeddings
        career_embeddings = embedding_service.load_cached_career_embeddings()
        
        matches = []
        for career in career_db.list_careers():
            # Get semantic similarity
            career_vector = career_embeddings.get(career.id)
            if career_vector is None:
                # Fallback: compute on the fly if cache is missing
                desc_to_embed = f"{career.title}: {career.description}"
                career_vector = embedding_service.get_embedding(desc_to_embed)
                
            semantic_score = cosine_similarity(user_vector, career_vector)
            
            # Map required and preferred skill dictionaries
            user_skill_levels = {name: info["level"] for name, info in user_skills.items()}
            
            skill_score = calculate_skill_match_score(
                user_skills=user_skill_levels,
                required_skills=career.required_skills,
                preferred_skills=career.preferred_skills
            )
            
            # Combine scores: 70% structured skill overlap, 30% semantic interest overlap
            combined_score = (skill_score * 0.7) + (semantic_score * 0.3)
            
            # Ensure within 0 to 1 limit
            combined_score = max(0.0, min(1.0, combined_score))
            
            matches.append({
                "career_id": career.id,
                "title": career.title,
                "match_score": combined_score,
                "skill_score": skill_score,
                "semantic_score": semantic_score
            })
            
        # Sort matches by score descending
        matches.sort(key=lambda x: x["match_score"], reverse=True)
        return matches

# Singleton instance
career_matcher = CareerMatcher()
