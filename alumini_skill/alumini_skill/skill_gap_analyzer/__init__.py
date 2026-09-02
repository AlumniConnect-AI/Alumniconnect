"""
Skill Gap Analyzer Module for EduBridge AI.
Detects missing student skills, calculates readiness score, and recommends targeted courses & projects.
"""

from .models import (
    SkillGapRequest,
    JobDescriptionGapRequest,
    SkillGapResponse,
    CourseRecommendation,
    ProjectRecommendation,
    BenchmarkRoleInfo,
)
from .analyzer import SkillGapAnalyzer
from .taxonomy import SKILL_TAXONOMY, normalize_skill, categorize_skill
from .benchmarks import BENCHMARK_ROLES, get_benchmark_role, list_available_roles
from .recommender import CourseRecommender, ProjectRecommender

__all__ = [
    "SkillGapAnalyzer",
    "SkillGapRequest",
    "JobDescriptionGapRequest",
    "SkillGapResponse",
    "CourseRecommendation",
    "ProjectRecommendation",
    "BenchmarkRoleInfo",
    "SKILL_TAXONOMY",
    "BENCHMARK_ROLES",
    "normalize_skill",
    "categorize_skill",
    "get_benchmark_role",
    "list_available_roles",
    "CourseRecommender",
    "ProjectRecommender",
]

