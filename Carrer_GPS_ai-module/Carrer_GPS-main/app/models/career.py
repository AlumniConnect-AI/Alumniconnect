from typing import Dict, List
from pydantic import BaseModel, Field

class CareerDetail(BaseModel):
    id: str
    title: str
    description: str
    required_skills: Dict[str, int] = Field(default_factory=dict)
    preferred_skills: Dict[str, int] = Field(default_factory=dict)
    recommended_projects: List[str] = Field(default_factory=list)
    career_progression: List[str] = Field(default_factory=list)
    related_careers: List[str] = Field(default_factory=list)
    education_relevance: Dict[str, float] = Field(default_factory=dict)
    typical_experience_years: int = Field(default=0, ge=0)
