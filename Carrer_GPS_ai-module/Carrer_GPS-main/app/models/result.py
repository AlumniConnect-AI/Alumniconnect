from typing import List, Dict, Any
from pydantic import BaseModel, Field
from app.models.skill import SkillGap
from app.models.roadmap import CareerRoadmap

class UserState(BaseModel):
    current_role: str
    career_level: str

class TargetInfo(BaseModel):
    career: str
    timeline_months: int

class ReadinessInfo(BaseModel):
    score: int
    details: Dict[str, int] = Field(default_factory=dict)
    explanation: str = Field(default="")

class Personalization(BaseModel):
    summary: str
    strengths: List[str] = Field(default_factory=list)
    priority_gaps: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    roadmap_explanation: str
    next_best_action: str
    risks: List[str] = Field(default_factory=list)

class CareerGPSResult(BaseModel):
    user_state: UserState
    target: TargetInfo
    readiness: ReadinessInfo
    skill_gaps: List[SkillGap] = Field(default_factory=list)
    recommended_projects: List[Dict[str, Any]] = Field(default_factory=list)
    roadmap: CareerRoadmap
    personalization: Personalization
    confidence: float = Field(..., ge=0.0, le=1.0)
