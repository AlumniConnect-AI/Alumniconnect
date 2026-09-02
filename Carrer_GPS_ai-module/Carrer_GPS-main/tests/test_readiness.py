import pytest
from app.models.profile import CareerProfile
from app.knowledge.career_database import career_db
from app.engine.readiness_scorer import readiness_scorer

def test_readiness_calculation():
    target_career = career_db.get_career_by_id("flutter-developer")
    assert target_career is not None
    
    # Profile A: Beginner with minimal profile details
    profile_a = CareerProfile(
        education={"degree": "B.Tech", "field": "Computer Science"},
        current_role="Student",
        skills=[{"name": "Dart", "level": 1}],
        projects=[],
        target_career="Flutter Developer"
    )
    
    # Profile B: Strong profile with projects, experience, and certifications
    profile_b = CareerProfile(
        education={"degree": "B.Tech", "field": "Computer Science"},
        current_role="Developer",
        skills=[
            {"name": "Dart", "level": 4},
            {"name": "Flutter", "level": 4},
            {"name": "Git", "level": 3},
            {"name": "REST APIs", "level": 3}
        ],
        projects=[{
            "name": "E-Commerce App",
            "description": "Flutter app with rest apis integration",
            "technologies": ["Flutter", "Dart", "REST APIs"]
        }],
        experience=[{
            "role": "Flutter Developer Intern",
            "duration_months": 12.0,
            "skills": ["Flutter", "Dart"]
        }],
        certifications=[{"name": "Google Certified Associate Android Developer"}],
        target_career="Flutter Developer"
    )
    
    # Analyze effective skills for both
    skills_a = {
        "Dart": {"name": "Dart", "level": 1, "evidence": [], "category": "Mobile Development"}
    }
    res_a = readiness_scorer.calculate_readiness(profile_a, target_career, skills_a, 0.0)
    
    skills_b = {
        "Dart": {"name": "Dart", "level": 4, "evidence": [], "category": "Mobile Development"},
        "Flutter": {"name": "Flutter", "level": 4, "evidence": ["E-Commerce App"], "category": "Mobile Development"},
        "Git": {"name": "Git", "level": 3, "evidence": [], "category": "General Engineering"},
        "REST APIs": {"name": "REST APIs", "level": 3, "evidence": ["E-Commerce App"], "category": "Backend Development"}
    }
    res_b = readiness_scorer.calculate_readiness(profile_b, target_career, skills_b, 12.0)
    
    # Assert Profile B is ready and scores higher
    assert res_b["score"] > res_a["score"]
    assert res_b["score"] >= 55
    assert res_a["score"] < 40
    
    # Check that score details are present
    assert "skill_match" in res_b["details"]
    assert "project_match" in res_b["details"]
    assert "experience_match" in res_b["details"]
