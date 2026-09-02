"""
Mentor Match Engine — Alumni Mentor Recommendation Module
=========================================================
Recommends the best alumni mentors for students using SBERT
text embeddings and cosine similarity.

Part of the AlumniConnect AI platform.
Sibling module to career_twin/.

Usage (future):
    from mentor_match_engine.engine import MentorMatchEngine

    results = MentorMatchEngine.find_mentors(
        student_profile=...,
        mentor_pool=...,
        top_n=5,
    )
"""

from .engine import MentorMatchEngine

__all__ = ["MentorMatchEngine"]
__version__ = "0.1.0"
