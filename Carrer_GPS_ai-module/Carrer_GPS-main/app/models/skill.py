from typing import List
from pydantic import BaseModel, Field

class SkillCatalogEntry(BaseModel):
    name: str
    category: str

class SkillGap(BaseModel):
    skill: str
    current_level: int = Field(default=0, ge=0, le=5)
    required_level: int = Field(default=0, ge=0, le=5)
    gap: int = Field(default=0)
    priority_score: float = Field(default=0.0)
    priority: str = Field(default="NONE") # HIGH, MEDIUM, LOW, NONE
    evidence: List[str] = Field(default_factory=list)
    reason: str = Field(default="")
