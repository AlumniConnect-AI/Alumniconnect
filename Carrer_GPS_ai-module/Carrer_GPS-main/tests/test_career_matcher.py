import pytest
from app.engine.career_matcher import career_matcher

def test_career_matcher_ranking():
    # Setup mock user skills and interests typical for a Flutter developer
    user_skills = {
        "Flutter": {"level": 4, "evidence": ["Built AlumniConnect"]},
        "Dart": {"level": 4, "evidence": ["Built AlumniConnect"]},
        "Firebase": {"level": 3, "evidence": []},
        "Git": {"level": 3, "evidence": []},
        "REST APIs": {"level": 3, "evidence": []}
    }
    user_interests = ["Mobile Development", "App Development"]
    current_role = "Student"
    
    matches = career_matcher.match_careers(
        user_skills=user_skills,
        user_interests=user_interests,
        current_role=current_role
    )
    
    # Assert we got some matches
    assert len(matches) > 0
    
    # Assert Flutter Developer or Mobile Developer is ranked highly
    top_match = matches[0]
    assert top_match["career_id"] in ["flutter-developer", "mobile-developer", "mobile-app-developer", "mobile-qa-engineer"]
    assert top_match["match_score"] > 0.3
    
    # Assert unrelated careers (like Data Scientist) are ranked lower
    data_science_match = next((m for m in matches if m["career_id"] == "data-scientist"), None)
    if data_science_match:
        assert top_match["match_score"] > data_science_match["match_score"]
