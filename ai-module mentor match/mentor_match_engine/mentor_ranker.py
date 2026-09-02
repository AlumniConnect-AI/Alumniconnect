"""
Mentor Match Engine — Mentor Ranker
=====================================
Ranks candidate alumni mentor profiles based on Cosine Similarity scores,
computes technical skill overlap, generates human-readable match explanations,
and returns structured MentorMatchResult objects.
"""

import logging
from typing import List, Optional

from .models import StudentProfile, MentorProfile, MentorMatchResult
from .similarity_engine import SimilarityEngine

logger = logging.getLogger(__name__)


class MentorRanker:
    """Ranks mentors based on Cosine Similarity and builds enriched result models."""

    @staticmethod
    def compute_skill_overlap(
        student_skills: List[str],
        mentor_skills: List[str],
    ) -> List[str]:
        """Find technical skills that appear in both student and mentor profile lists.

        Args:
            student_skills: List of student skills.
            mentor_skills: List of mentor skills.

        Returns:
            Sorted list of overlapping skills (case-insensitive deduplication).
        """
        if not student_skills or not mentor_skills:
            return []

        student_set = {s.lower().strip() for s in student_skills if s and s.strip()}
        mentor_set = {s.lower().strip() for s in mentor_skills if s and s.strip()}
        return sorted(list(student_set.intersection(mentor_set)))

    @staticmethod
    def generate_match_reasons(
        student: StudentProfile,
        mentor: MentorProfile,
        matched_skills: List[str],
        similarity_score: float,
    ) -> List[str]:
        """Generate human-readable explanations detailing why this mentor matched.

        Args:
            student: Student profile.
            mentor: Mentor profile.
            matched_skills: Overlapping skills list.
            similarity_score: Cosine similarity score (0.0 to 1.0).

        Returns:
            List of human-readable match reason strings.
        """
        reasons = []

        # 1. Skill overlap
        if matched_skills:
            top_skills = ", ".join(matched_skills[:4])
            reasons.append(
                f"🎯 Shares {len(matched_skills)} skill(s) with you: {top_skills}"
            )

        # 2. Domain & interest alignment
        if mentor.career_domain and student.interests:
            domain_lower = mentor.career_domain.lower()
            matching_interests = [
                interest for interest in student.interests
                if interest and interest.lower() in domain_lower
            ]
            if matching_interests:
                reasons.append(
                    f"🔮 Expertise in your interest area: {mentor.career_domain}"
                )

        # 3. Department alignment
        if (
            student.department
            and mentor.department
            and student.department.lower().strip() == mentor.department.lower().strip()
        ):
            reasons.append(f"🏫 Same department alumni: {mentor.department}")

        # 4. Industry experience
        if mentor.experience_years >= 5:
            reasons.append(
                f"⏱ {mentor.experience_years:.0f}+ years of professional experience"
            )

        # 5. Semantic similarity tier
        if similarity_score >= 0.70:
            reasons.append("🌟 Exceptionally high profile semantic alignment")
        elif similarity_score >= 0.50:
            reasons.append("✅ Strong overall career profile match")

        # 6. Current role & company
        if mentor.current_role and mentor.company:
            reasons.append(
                f"💼 Currently: {mentor.current_role} at {mentor.company}"
            )

        # Fallback
        if not reasons:
            reasons.append("📋 Included based on overall profile similarity")

        return reasons

    @classmethod
    def rank_mentors(
        cls,
        student: StudentProfile,
        mentors: List[MentorProfile],
        similarity_scores: List[float],
        top_k: int = 5,
    ) -> List[MentorMatchResult]:
        """Sort mentors by similarity score in descending order and return top_k matches.

        Args:
            student: Student seeking recommendations.
            mentors: List of available candidate mentors.
            similarity_scores: List of cosine similarity scores (one per mentor).
            top_k: Number of top recommendations to return (must be > 0).

        Returns:
            List of MentorMatchResult objects, ranked 1 to min(top_k, len(mentors)).

        Raises:
            ValueError: If top_k <= 0 or if mentors and scores lengths mismatch.
        """
        if top_k <= 0:
            raise ValueError(f"top_k must be greater than 0, got {top_k}.")

        if not mentors:
            return []

        if len(mentors) != len(similarity_scores):
            raise ValueError(
                f"Length mismatch: {len(mentors)} mentors vs {len(similarity_scores)} similarity scores."
            )

        # Zip mentors with scores
        scored_pairs = list(zip(mentors, similarity_scores))

        # Sort descending by similarity score
        scored_pairs.sort(key=lambda pair: pair[1], reverse=True)

        # Select top_k (or all available if fewer than top_k exist)
        selected_pairs = scored_pairs[:min(top_k, len(scored_pairs))]

        results = []
        for rank, (mentor, score) in enumerate(selected_pairs, start=1):
            matched_skills = cls.compute_skill_overlap(
                student.skills if student else [],
                mentor.skills if mentor else [],
            )
            match_reasons = cls.generate_match_reasons(
                student, mentor, matched_skills, score
            )
            match_pct = SimilarityEngine.similarity_to_percentage(score)

            result = MentorMatchResult(
                mentor=mentor,
                similarity_score=float(score),
                match_percentage=match_pct,
                matched_skills=matched_skills,
                match_reasons=match_reasons,
                rank=rank,
            )
            results.append(result)

        return results
