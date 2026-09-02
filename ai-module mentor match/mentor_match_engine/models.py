"""
Mentor Match Engine — Data Models
==================================
Clean data structures for the mentor matching pipeline.
Uses Python dataclasses for type safety and clarity.
"""

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class StudentProfile:
    """Represents a student seeking mentor recommendations.

    Attributes:
        student_id:      Unique identifier for the student.
        name:            Full name.
        department:      Academic department (e.g., "Computer Science").
        skills:          List of technical/soft skills.
        interests:       List of career interests or topics.
        career_goals:    Free-text description of career aspirations.
        bio:             Short biography or summary.
        education:       Degree information (e.g., "B.Tech Computer Science").
        experience_years: Years of experience (0 for freshers).
    """
    student_id: str
    name: str
    department: str = ""
    skills: List[str] = field(default_factory=list)
    interests: List[str] = field(default_factory=list)
    career_goals: str = ""
    bio: str = ""
    education: str = ""
    experience_years: float = 0.0

    def to_text(self) -> str:
        """Converts the student profile into a single text representation
        suitable for embedding generation.
        """
        parts = []
        if self.name:
            parts.append(f"Name: {self.name}")
        if self.education:
            parts.append(f"Education: {self.education}")
        if self.department:
            parts.append(f"Department: {self.department}")
        if self.skills:
            parts.append(f"Skills: {', '.join(self.skills)}")
        if self.interests:
            parts.append(f"Interests: {', '.join(self.interests)}")
        if self.career_goals:
            parts.append(f"Career Goals: {self.career_goals}")
        if self.bio:
            parts.append(f"Bio: {self.bio}")
        if self.experience_years > 0:
            parts.append(f"Experience: {self.experience_years} years")
        return "\n".join(parts)


@dataclass
class MentorProfile:
    """Represents an alumni mentor available for matching.

    Attributes:
        mentor_id:       Unique identifier for the mentor.
        name:            Full name.
        current_role:    Current job title/designation.
        company:         Current company/organization.
        experience_years: Total years of professional experience.
        skills:          List of technical/soft skills.
        interests:       List of professional interests or domains.
        career_domain:   Primary career domain (e.g., "AI/ML", "Mobile Dev").
        education:       Degree information.
        bio:             Short professional biography.
        department:      Alumni's original academic department.
    """
    mentor_id: str
    name: str
    current_role: str = ""
    company: str = ""
    experience_years: float = 0.0
    skills: List[str] = field(default_factory=list)
    interests: List[str] = field(default_factory=list)
    career_domain: str = ""
    education: str = ""
    bio: str = ""
    department: str = ""

    def to_text(self) -> str:
        """Converts the mentor profile into a single text representation
        suitable for embedding generation.
        """
        parts = []
        if self.name:
            parts.append(f"Name: {self.name}")
        if self.current_role:
            parts.append(f"Role: {self.current_role}")
        if self.company:
            parts.append(f"Company: {self.company}")
        if self.education:
            parts.append(f"Education: {self.education}")
        if self.career_domain:
            parts.append(f"Domain: {self.career_domain}")
        if self.skills:
            parts.append(f"Skills: {', '.join(self.skills)}")
        if self.interests:
            parts.append(f"Interests: {', '.join(self.interests)}")
        if self.bio:
            parts.append(f"Bio: {self.bio}")
        if self.experience_years > 0:
            parts.append(f"Experience: {self.experience_years} years")
        return "\n".join(parts)


@dataclass
class MentorMatchResult:
    """A single mentor match result with scoring details.

    Attributes:
        mentor:            The matched MentorProfile.
        similarity_score:  Cosine similarity score (0.0 to 1.0).
        match_percentage:  Human-readable percentage (0–100).
        matched_skills:    Skills that overlap between student and mentor.
        match_reasons:     Human-readable reasons for the match.
        rank:              Position in the final ranked list (1 = best).
    """
    mentor: MentorProfile
    similarity_score: float = 0.0
    match_percentage: float = 0.0
    matched_skills: List[str] = field(default_factory=list)
    match_reasons: List[str] = field(default_factory=list)
    rank: int = 0

    def to_dict(self) -> dict:
        """Serializes the match result to a JSON-compatible dictionary."""
        return {
            "rank": self.rank,
            "mentor_id": self.mentor.mentor_id,
            "mentor_name": self.mentor.name,
            "current_role": self.mentor.current_role,
            "company": self.mentor.company,
            "career_domain": self.mentor.career_domain,
            "similarity_score": round(self.similarity_score, 4),
            "match_percentage": round(self.match_percentage, 1),
            "matched_skills": self.matched_skills,
            "match_reasons": self.match_reasons,
        }
