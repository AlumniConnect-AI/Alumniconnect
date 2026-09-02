from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class SkillDetail(BaseModel):
    skill_name: str
    category: str = "General"
    importance: str = "Critical"  # Critical, Secondary, Bonus
    weight: float = 1.0
    status: str = "Missing"  # Matched, Missing, Partial
    similarity_score: float = 0.0
    matched_with: Optional[str] = None


class CourseRecommendation(BaseModel):
    skill: str
    title: str
    provider: str  # e.g., Coursera, NPTEL, Udemy, edX, YouTube, Official Docs
    difficulty: str = "Beginner"  # Beginner, Intermediate, Advanced
    duration: str = "4-6 weeks"
    rating: float = 4.8
    url: str
    is_free: bool = True
    description: str


class ProjectRecommendation(BaseModel):
    title: str
    difficulty: str = "Intermediate"  # Beginner, Intermediate, Advanced
    estimated_hours: int = 20
    missing_skills_covered: List[str] = Field(default_factory=list)
    tech_stack: List[str] = Field(default_factory=list)
    summary: str
    key_features: List[str] = Field(default_factory=list)
    github_template_or_guide: Optional[str] = None


class CategoryScore(BaseModel):
    category: str
    matched_count: int
    total_count: int
    score_percentage: float


class BenchmarkRoleInfo(BaseModel):
    role_id: str
    role_name: str
    description: str
    core_skills: List[str]
    secondary_skills: List[str]
    total_skills_count: int


class SkillGapRequest(BaseModel):
    student_name: Optional[str] = "Student"
    student_skills: List[str] = Field(..., description="List of skills currently possessed by the student")
    target_role: Optional[str] = Field("Full Stack Developer", description="Target job role benchmark ID or name")
    custom_benchmark_skills: Optional[List[str]] = Field(
        default=None, description="Optional custom target skills (overrides benchmark role if provided)"
    )
    experience_level: Optional[str] = Field("Entry Level", description="Target level: Entry Level, Mid Level, Senior")
    target_company: Optional[str] = None


class JobDescriptionGapRequest(BaseModel):
    student_name: Optional[str] = "Student"
    student_skills: List[str] = Field(..., description="List of student skills")
    job_description_text: str = Field(..., description="Raw text of the job description or posting")
    target_role: Optional[str] = Field("Custom Role", description="Optional label for the role")


class SkillGapResponse(BaseModel):
    student_name: str
    target_role: str
    placement_readiness_score: float = Field(..., description="Readiness score from 0.0 to 100.0%")
    readiness_level: str = Field(..., description="Job Ready, Near Ready, Needs Upskilling, Foundational")
    total_benchmark_skills: int
    total_student_skills: int
    matched_skills_count: int
    missing_skills_count: int
    matched_skills: List[SkillDetail] = Field(default_factory=list)
    missing_critical_skills: List[SkillDetail] = Field(default_factory=list)
    missing_secondary_skills: List[SkillDetail] = Field(default_factory=list)
    strengths_or_bonus_skills: List[str] = Field(default_factory=list)
    category_breakdown: List[CategoryScore] = Field(default_factory=list)
    recommended_courses: List[CourseRecommendation] = Field(default_factory=list)
    recommended_projects: List[ProjectRecommendation] = Field(default_factory=list)
    action_plan: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)
