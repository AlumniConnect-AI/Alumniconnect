"""
Comprehensive Unit and Functional Tests for Skill Gap Analyzer Engine.
Tests taxonomy normalization, gap calculation, placement readiness scoring,
and course/project recommendations.
"""

import pytest
from skill_gap_analyzer.models import SkillGapRequest, JobDescriptionGapRequest
from skill_gap_analyzer.analyzer import SkillGapAnalyzer
from skill_gap_analyzer.taxonomy import normalize_skill, categorize_skill, extract_skills_from_text
from skill_gap_analyzer.benchmarks import get_benchmark_role, list_available_roles
from skill_gap_analyzer.recommender import CourseRecommender, ProjectRecommender


@pytest.fixture
def analyzer():
    return SkillGapAnalyzer()


def test_taxonomy_normalization():
    """Verify alias and synonym resolution."""
    assert normalize_skill("react.js") == "React"
    assert normalize_skill("reactjs") == "React"
    assert normalize_skill("k8s") == "Kubernetes"
    assert normalize_skill("py") == "Python"
    assert normalize_skill("ml") == "Machine Learning"
    assert normalize_skill("dsa") == "Data Structures & Algorithms"
    assert normalize_skill("node") == "Node.js"


def test_skill_categorization():
    """Verify correct domain classification of technical skills."""
    assert categorize_skill("React") == "Frontend Development"
    assert categorize_skill("FastAPI") == "Backend & APIs"
    assert categorize_skill("Kubernetes") == "Cloud & DevOps"
    assert categorize_skill("PyTorch") == "AI, ML & Data Science"
    assert categorize_skill("PostgreSQL") == "Databases & Caching"


def test_text_skill_extraction():
    """Verify automated skill extraction from free-form text."""
    sample_text = """
    We are looking for a Software Engineer proficient in Python, React, and PostgreSQL.
    Experience with Docker, Kubernetes, and CI/CD pipelines is a huge plus.
    Candidate must have strong foundations in Data Structures and Algorithms.
    """
    extracted = extract_skills_from_text(sample_text)
    assert "Python" in extracted
    assert "React" in extracted
    assert "PostgreSQL" in extracted
    assert "Docker" in extracted
    assert "Kubernetes" in extracted
    assert "CI/CD Pipelines" in extracted


def test_benchmark_roles_catalog():
    """Verify benchmark role registry contains required roles."""
    roles = list_available_roles()
    role_ids = [r["role_id"] for r in roles]
    assert "full_stack_developer" in role_ids
    assert "ai_ml_engineer" in role_ids
    assert "cloud_devops_engineer" in role_ids
    assert "backend_engineer" in role_ids


def test_full_stack_gap_analysis(analyzer):
    """Test full stack developer skill gap detection with a student profile."""
    student_skills = ["JavaScript", "HTML5", "CSS3", "Git", "Python"]
    req = SkillGapRequest(
        student_name="Rahul Sharma",
        student_skills=student_skills,
        target_role="Full Stack Web Developer",
        experience_level="Entry Level"
    )
    res = analyzer.analyze(req)

    # Basic validations
    assert res.student_name == "Rahul Sharma"
    assert res.target_role == "Full Stack Web Developer"
    assert 0.0 <= res.placement_readiness_score <= 100.0
    assert len(res.matched_skills) > 0
    assert len(res.missing_critical_skills) > 0

    # Missing critical should include core fullstack tech like React / Node.js
    missing_critical_names = [s.skill_name for s in res.missing_critical_skills]
    assert "React" in missing_critical_names or "Node.js" in missing_critical_names

    # Recommended courses and projects should be populated
    assert len(res.recommended_courses) > 0
    assert len(res.recommended_projects) > 0
    assert len(res.action_plan) > 0


def test_ai_ml_engineer_gap_analysis(analyzer):
    """Test AI/ML Engineer profile gap detection."""
    student_skills = ["Python", "Pandas", "NumPy", "Scikit-Learn", "Machine Learning"]
    req = SkillGapRequest(
        student_name="Ananya Verma",
        student_skills=student_skills,
        target_role="ai_ml_engineer"
    )
    res = analyzer.analyze(req)

    # Student has good base (34.7%), but missing Deep Learning / PyTorch
    assert res.placement_readiness_score >= 30.0
    missing_names = [s.skill_name for s in res.missing_critical_skills + res.missing_secondary_skills]
    assert "PyTorch" in missing_names or "Deep Learning" in missing_names


    # Verify project recommendations are relevant
    project_titles = [p.title for p in res.recommended_projects]
    assert any("AI" in t or "Resume" in t or "LLM" in t for t in project_titles)


def test_job_description_analysis(analyzer):
    """Test analysis directly from a job posting description."""
    jd_text = """
    Hiring Frontend Developer:
    Must know React, TypeScript, Tailwind CSS, Redux, and REST APIs.
    Familiarity with Next.js and Jest testing is preferred.
    """
    student_skills = ["React", "HTML5", "CSS3", "JavaScript"]
    req = JobDescriptionGapRequest(
        student_name="Dev Patel",
        student_skills=student_skills,
        job_description_text=jd_text,
        target_role="Frontend Role"
    )
    res = analyzer.analyze_from_job_description(req)

    assert res.placement_readiness_score > 0.0
    missing_names = [s.skill_name for s in res.missing_critical_skills + res.missing_secondary_skills]
    assert "TypeScript" in missing_names or "Tailwind CSS" in missing_names


def test_course_and_project_recommenders():
    """Verify course and project recommenders return structured results."""
    courses = CourseRecommender.recommend_for_skills(["Docker", "React"])
    assert len(courses) >= 2
    assert courses[0].url.startswith("http")

    projects = ProjectRecommender.recommend_for_gaps(["Docker", "Redis", "Node.js"], target_role_id="backend_engineer")
    assert len(projects) > 0
    assert len(projects[0].tech_stack) > 0
