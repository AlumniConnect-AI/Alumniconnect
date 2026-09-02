"""
Mentor Match Engine — Main Orchestrator
=========================================
Top-level engine connecting the complete semantic recommendation pipeline:

    Student Profile
          │
          ▼
   ProfileEncoder (SBERT embedding: 384-dim)
          │
          ▼
   SimilarityEngine (Cosine similarity math)
          │
          ▼
   MentorRanker (Top-K sorting + skill overlap + reasons)
          │
          ▼
   List[MentorMatchResult]

Usage:
    from mentor_match_engine.engine import MentorMatchEngine

    # Load sample data
    mentors = MentorMatchEngine.load_sample_mentors()

    # Find top matches
    results = MentorMatchEngine.match_student(student, mentors, top_k=5)
"""

import json
import os
import logging
from typing import List, Optional, Union, Any

from .models import StudentProfile, MentorProfile, MentorMatchResult
from .profile_encoder import ProfileEncoder
from .similarity_engine import SimilarityEngine
from .mentor_ranker import MentorRanker

logger = logging.getLogger(__name__)


class MentorMatchEngine:
    """Top-level orchestrator for the Mentor Match Engine pipeline.

    Stateless class methods design. Lazily instantiates the SBERT ProfileEncoder.
    """

    _encoder: Optional[ProfileEncoder] = None

    @classmethod
    def _get_encoder(cls) -> ProfileEncoder:
        """Lazy-initialize and return the shared ProfileEncoder instance."""
        if cls._encoder is None:
            cls._encoder = ProfileEncoder()
        return cls._encoder

    @classmethod
    def match_student(
        cls,
        student_profile: StudentProfile,
        mentor_pool: List[MentorProfile],
        top_k: int = 5,
    ) -> List[MentorMatchResult]:
        """Match a student profile against a pool of alumni mentors using SBERT + Cosine Similarity.

        Pipeline Steps:
            1. Validate inputs (student profile and mentor pool).
            2. Encode student profile into a 384-dim vector using ProfileEncoder.
            3. Encode mentor profiles into a matrix of 384-dim vectors.
            4. Calculate Cosine Similarity between student vector and mentor matrix.
            5. Rank mentors in descending order of similarity and return top_k matches.

        Args:
            student_profile: StudentProfile seeking recommendations.
            mentor_pool: List of candidate MentorProfile objects.
            top_k: Maximum number of top recommendations to return (default 5).

        Returns:
            List of ranked MentorMatchResult objects.

        Raises:
            ValueError: If student_profile is None or top_k <= 0.
        """
        if student_profile is None:
            raise ValueError("student_profile cannot be None.")

        if top_k <= 0:
            raise ValueError(f"top_k must be greater than 0, got {top_k}.")

        if not mentor_pool:
            return []

        encoder = cls._get_encoder()

        # 1. Encode student profile
        student_vec = encoder.encode_student_profile(student_profile, normalize_embeddings=True)

        # 2. Encode mentor pool (batch)
        mentor_matrix = encoder.encode_profiles(mentor_pool, normalize_embeddings=True, show_progress_bar=False)

        # 3. Calculate cosine similarity
        similarity_scores = SimilarityEngine.batch_cosine_similarity(student_vec, mentor_matrix)

        # 4. Rank mentors and generate match reasons
        results = MentorRanker.rank_mentors(
            student=student_profile,
            mentors=mentor_pool,
            similarity_scores=similarity_scores.tolist(),
            top_k=top_k,
        )

        return results

    @classmethod
    def find_mentors(
        cls,
        student_profile: StudentProfile,
        mentor_pool: List[MentorProfile],
        top_n: int = 5,
    ) -> List[MentorMatchResult]:
        """Backward-compatible alias for match_student."""
        return cls.match_student(student_profile, mentor_pool, top_k=top_n)

    @classmethod
    def find_mentors_formatted(
        cls,
        student_profile: StudentProfile,
        mentor_pool: List[MentorProfile],
        top_k: int = 5,
    ) -> str:
        """Returns match results formatted as a pretty-printed JSON string."""
        results = cls.match_student(student_profile, mentor_pool, top_k=top_k)
        return json.dumps(
            [r.to_dict() for r in results],
            indent=2,
            ensure_ascii=False,
        )

    @classmethod
    def load_sample_mentors(cls) -> List[MentorProfile]:
        """Load sample mentor profiles from bundled data/sample_mentors.json."""
        data_path = os.path.join(
            os.path.dirname(__file__), "data", "sample_mentors.json"
        )
        if not os.path.exists(data_path):
            raise FileNotFoundError(f"Sample mentors JSON file not found at: {data_path}")

        with open(data_path, "r", encoding="utf-8") as f:
            raw_mentors = json.load(f)

        mentors = []
        for m in raw_mentors:
            mentors.append(
                MentorProfile(
                    mentor_id=m.get("mentor_id", ""),
                    name=m.get("name", ""),
                    current_role=m.get("current_role", ""),
                    company=m.get("company", ""),
                    experience_years=float(m.get("experience_years", 0.0)),
                    skills=m.get("skills", []),
                    interests=m.get("interests", []),
                    career_domain=m.get("career_domain", ""),
                    education=m.get("education", ""),
                    bio=m.get("bio", ""),
                    department=m.get("department", ""),
                )
            )
        return mentors

    @classmethod
    def is_sbert_ready(cls) -> bool:
        """Check if SBERT model is currently loaded in memory."""
        encoder = cls._get_encoder()
        return encoder.is_model_loaded()
