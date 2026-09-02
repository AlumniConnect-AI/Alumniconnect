import pytest
from app.models.profile import CareerProfile
from app.models.skill import SkillGap
from app.knowledge.career_database import career_db
from app.engine.roadmap_planner import roadmap_planner

def test_roadmap_sequencing():
    target_career = career_db.get_career_by_id("flutter-developer")
    assert target_career is not None
    
    profile = CareerProfile(
        education={"degree": "B.Tech", "field": "Computer Science"},
        current_role="Student",
        skills=[], # No skills, has gaps in everything
        projects=[],
        target_career="Flutter Developer",
        target_duration_months=6
    )
    
    # Setup dummy skill gaps with prerequisites
    # Dart -> Flutter -> State Management -> Testing -> CI/CD
    gaps = [
        SkillGap(skill="Dart", current_level=0, required_level=4, gap=4, priority_score=10.0, priority="HIGH"),
        SkillGap(skill="Flutter", current_level=0, required_level=4, gap=4, priority_score=9.5, priority="HIGH"),
        SkillGap(skill="State Management", current_level=0, required_level=4, gap=4, priority_score=8.5, priority="HIGH"),
        SkillGap(skill="Testing", current_level=0, required_level=3, gap=3, priority_score=7.0, priority="MEDIUM"),
        SkillGap(skill="CI/CD", current_level=0, required_level=3, gap=3, priority_score=6.0, priority="MEDIUM")
    ]
    
    roadmap = roadmap_planner.generate_roadmap(profile, target_career, gaps)
    
    assert len(roadmap.phases) == 3 # 6 months is mapped to 3 phases
    
    # Get flat list of skills ordered by phase
    phase_skills = [s for phase in roadmap.phases for s in phase.skills]
    
    # Assert Dart is in Phase 1
    assert "Dart" in roadmap.phases[0].skills
    
    # Assert Flutter is in Phase 1 or 2
    assert "Flutter" in roadmap.phases[0].skills or "Flutter" in roadmap.phases[1].skills
    
    # Assert CI/CD is in a later phase than Dart
    dart_idx = phase_skills.index("Dart")
    cicd_idx = phase_skills.index("CI/CD")
    assert cicd_idx > dart_idx
    
    # Assert State Management is in a later phase than Dart
    state_idx = phase_skills.index("State Management")
    assert state_idx > dart_idx
