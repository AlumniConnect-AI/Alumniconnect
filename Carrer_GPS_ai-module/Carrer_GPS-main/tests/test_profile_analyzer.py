import pytest
from app.models.profile import CareerProfile, SkillProfile, ProjectProfile
from app.engine.profile_analyzer import profile_analyzer

def test_profile_analyzer_normalization():
    # Setup profile with variations of skill names
    profile = CareerProfile(
        education={"degree": "B.Tech", "field": "Computer Science"},
        current_role="Student",
        skills=[
            {"name": "flutter development", "level": 3, "years": 1.0},
            {"name": "Flutter SDK", "level": 4, "years": 0.5},
            {"name": "react.js", "level": 2, "years": 1.0}
        ],
        projects=[],
        target_career="Flutter Developer",
        target_duration_months=6
    )
    
    result = profile_analyzer.analyze_profile(profile)
    skills = result["effective_skills"]
    
    # Assert alias normalization and deduplication (keeping max level 4)
    assert "Flutter" in skills
    assert skills["Flutter"]["level"] == 4
    
    assert "React" in skills
    assert skills["React"]["level"] == 2

def test_profile_analyzer_evidence_extraction():
    # Setup profile with projects to verify evidence parsing
    profile = CareerProfile(
        education={"degree": "B.Tech", "field": "Computer Science"},
        current_role="Student",
        skills=[
            {"name": "Flutter", "level": 3, "years": 1.0}
        ],
        projects=[
            {
                "name": "AlumniConnect",
                "description": "Built using Firebase auth and rest api integration",
                "technologies": ["Flutter"]
            }
        ],
        target_career="Flutter Developer",
        target_duration_months=6
    )
    
    result = profile_analyzer.analyze_profile(profile)
    skills = result["effective_skills"]
    
    # Assert evidence is linked and level bumped
    assert "Flutter" in skills
    assert "Project: AlumniConnect" in skills["Flutter"]["evidence"]
    assert skills["Flutter"]["level"] == 4 # Base 3 + 1 bump from project evidence
    
    # Assert skills extracted from project description text
    assert "Firebase" in skills
    assert skills["Firebase"]["level"] == 2 # Extracted baseline level
    assert "Project: AlumniConnect" in skills["Firebase"]["evidence"]

def test_profile_analyzer_career_level():
    # Test level deduction
    profile = CareerProfile(
        current_role="Student",
        skills=[{"name": "Java", "level": 2}],
        projects=[],
        target_career="Software Engineer",
        target_duration_months=6
    )
    res = profile_analyzer.analyze_profile(profile)
    assert res["career_level"] == "Beginner"
