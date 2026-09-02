from typing import List, Optional
from pydantic import BaseModel, Field

class RoadmapTask(BaseModel):
    title: str
    estimated_hours: int = Field(..., ge=0)
    priority: str = Field(default="MEDIUM") # HIGH, MEDIUM, LOW

class RoadmapPhase(BaseModel):
    phase: int
    title: str
    objective: str
    duration_weeks: int = Field(..., ge=1)
    skills: List[str] = Field(default_factory=list)
    tasks: List[RoadmapTask] = Field(default_factory=list)
    project: Optional[str] = None
    milestone: str
    expected_outcome: str

class CareerRoadmap(BaseModel):
    title: str
    duration_months: int = Field(..., ge=1)
    phases: List[RoadmapPhase] = Field(default_factory=list)
