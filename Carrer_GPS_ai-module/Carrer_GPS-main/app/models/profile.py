from typing import List, Optional
from pydantic import BaseModel, Field

class Education(BaseModel):
    degree: str
    field: str
    year: Optional[int] = None

class SkillProfile(BaseModel):
    name: str
    level: int = Field(..., ge=0, le=5)
    years: Optional[float] = Field(default=0.0, ge=0.0)
    evidence: Optional[List[str]] = Field(default_factory=list)

class ProjectProfile(BaseModel):
    name: str
    description: Optional[str] = ""
    technologies: List[str] = Field(default_factory=list)

class WorkExperience(BaseModel):
    role: str
    company: Optional[str] = ""
    duration_months: float = Field(default=0.0, ge=0.0)
    skills: List[str] = Field(default_factory=list)

class Certification(BaseModel):
    name: str
    issuer: Optional[str] = ""
    year: Optional[int] = None

class CareerProfile(BaseModel):
    education: Optional[Education] = None
    current_role: str
    skills: List[SkillProfile]
    projects: Optional[List[ProjectProfile]] = Field(default_factory=list)
    experience: Optional[List[WorkExperience]] = Field(default_factory=list)
    certifications: Optional[List[Certification]] = Field(default_factory=list)
    interests: Optional[List[str]] = Field(default_factory=list)
    target_career: str
    target_duration_months: int = Field(default=6, ge=1)
