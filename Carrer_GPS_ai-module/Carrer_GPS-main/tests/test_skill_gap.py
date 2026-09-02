import pytest
from app.knowledge.career_database import career_db
from app.engine.skill_gap_analyzer import skill_gap_analyzer

def test_skill_gap_analyzer():
    # Load Flutter Developer requirements
    target_career = career_db.get_career_by_id("flutter-developer")
    assert target_career is not None
    
    # Mock user skills: has Dart (level 4) but missing Flutter, State Management, and Testing
    user_skills = {
        "Dart": {"level": 4, "evidence": ["Built Console app"], "category": "Mobile Development"}
    }
    user_interests = ["Mobile Development"]
    
    gaps = skill_gap_analyzer.analyze_gaps(
        user_skills=user_skills,
        target_career=target_career,
        user_interests=user_interests
    )
    
    # Assert Dart is not a gap
    dart_gap = next((g for g in gaps if g.skill == "Dart"), None)
    assert dart_gap is not None
    assert dart_gap.gap == 0
    assert dart_gap.priority == "NONE"
    
    # Assert Flutter is a gap (since user does not have it, it's missing)
    flutter_gap = next((g for g in gaps if g.skill == "Flutter"), None)
    assert flutter_gap is not None
    assert flutter_gap.gap == 4
    assert flutter_gap.current_level == 0
    assert flutter_gap.required_level == 4
    assert flutter_gap.priority == "HIGH"
    
    # Assert testing is identified as a gap
    testing_gap = next((g for g in gaps if g.skill == "Testing"), None)
    assert testing_gap is not None
    assert testing_gap.gap == 3
