"""
Mentor Match Engine — Comprehensive Unit & Integration Tests
============================================================
Tests for:
  1. Profile & Match Result Data Models
  2. Structured Text Builder
  3. SBERT Profile Encoder (all-MiniLM-L6-v2)
  4. Cosine Similarity Engine (math, batch, dimensions, percentages)
  5. Mentor Ranker (sorting, top_k filtering, skill overlap, match reasons)
  6. End-to-End Orchestration (Student A vs Student B semantic differentiation)

Run:
  py mentor_match_engine/tests/test_mentor_match_engine.py
"""

import sys
import os
import json
import numpy as np

# Ensure parent ai-module directory is on sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from mentor_match_engine.models import (
    StudentProfile,
    MentorProfile,
    MentorMatchResult,
)
from mentor_match_engine.profile_encoder import ProfileEncoder, DEFAULT_MODEL_NAME
from mentor_match_engine.similarity_engine import SimilarityEngine
from mentor_match_engine.mentor_ranker import MentorRanker
from mentor_match_engine.engine import MentorMatchEngine


# ─────────────────────────────────────────────────────────────────────────────
#  TEST DATA FIXTURES
# ─────────────────────────────────────────────────────────────────────────────

def make_student_a() -> StudentProfile:
    """Student A: AI & Machine Learning Specialist."""
    return StudentProfile(
        student_id="STU_AI_01",
        name="Student A (AI Specialist)",
        department="Computer Science",
        skills=["python", "machine learning", "pytorch", "deep learning", "sql"],
        interests=["artificial intelligence", "computer vision"],
        career_goals="Seeking a career as an AI / Machine Learning Engineer",
        bio="Final year student focused on neural networks and deep learning models.",
        education="B.Tech Computer Science — 2025",
        experience_years=1.0,
    )


def make_student_b() -> StudentProfile:
    """Student B: Full Stack Web Developer."""
    return StudentProfile(
        student_id="STU_WEB_02",
        name="Student B (Web Developer)",
        department="Information Technology",
        skills=["react", "javascript", "node.js", "html", "css", "mongodb"],
        interests=["full stack web development", "cloud computing"],
        career_goals="Aspiring Full Stack Web Developer building web applications",
        bio="IT undergraduate building web applications with React and Node.js.",
        education="B.Sc Information Technology — 2025",
        experience_years=1.0,
    )


def make_mentors() -> list:
    """Sample candidate pool of 3 mentors."""
    return [
        MentorProfile(
            mentor_id="M001",
            name="Mentor Alpha (Mobile)",
            current_role="Flutter Developer",
            company="Mobile Corp",
            experience_years=5,
            skills=["flutter", "dart", "firebase", "git", "android"],
            interests=["mobile development"],
            career_domain="Mobile Development",
            education="B.Tech CS",
            department="Computer Science",
            bio="5 years building iOS and Android apps with Flutter.",
        ),
        MentorProfile(
            mentor_id="M002",
            name="Mentor Beta (AI/ML)",
            current_role="Senior ML Engineer",
            company="AI Labs",
            experience_years=6,
            skills=["python", "machine learning", "pytorch", "deep learning", "tensorflow"],
            interests=["artificial intelligence"],
            career_domain="AI / Machine Learning",
            education="M.Tech AI",
            department="Computer Science",
            bio="Senior ML engineer specializing in deep neural networks and computer vision.",
        ),
        MentorProfile(
            mentor_id="M003",
            name="Mentor Gamma (Web)",
            current_role="Senior Web Architect",
            company="Web Tech",
            experience_years=7,
            skills=["react", "javascript", "node.js", "express", "mongodb", "typescript"],
            interests=["full stack web development"],
            career_domain="Full Stack Web Development",
            education="BCA",
            department="Information Technology",
            bio="Architecting enterprise web systems using modern JavaScript frameworks.",
        ),
    ]


# ─────────────────────────────────────────────────────────────────────────────
#  1. MODEL TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_student_profile_creation():
    s = make_student_a()
    assert s.student_id == "STU_AI_01"
    assert s.name == "Student A (AI Specialist)"
    assert len(s.skills) == 5
    print("  ✅ test_student_profile_creation PASSED")


def test_mentor_profile_creation():
    mentors = make_mentors()
    assert len(mentors) == 3
    assert mentors[1].career_domain == "AI / Machine Learning"
    print("  ✅ test_mentor_profile_creation PASSED")


def test_match_result_to_dict():
    mentor = make_mentors()[0]
    result = MentorMatchResult(
        mentor=mentor,
        similarity_score=0.8765,
        match_percentage=87.7,
        matched_skills=["flutter", "git"],
        match_reasons=["Test reason"],
        rank=1,
    )
    d = result.to_dict()
    assert d["rank"] == 1
    assert d["mentor_name"] == "Mentor Alpha (Mobile)"
    assert d["similarity_score"] == 0.8765
    assert d["match_percentage"] == 87.7
    print("  ✅ test_match_result_to_dict PASSED")


# ─────────────────────────────────────────────────────────────────────────────
#  2. PROFILE ENCODER & TEXT CONVERSION TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_build_profile_text():
    student = make_student_a()
    text = ProfileEncoder.build_profile_text(student)
    assert "Student Name: Student A" in text
    assert "Skills: python, machine learning" in text
    assert "Career Goal: Seeking a career as an AI" in text
    print("  ✅ test_build_profile_text PASSED")


def test_sbert_encoder_loading_and_shape():
    encoder = ProfileEncoder()
    student = make_student_a()
    vec = encoder.encode_student_profile(student, normalize_embeddings=True)
    assert isinstance(vec, np.ndarray)
    assert vec.shape == (384,)
    assert abs(np.linalg.norm(vec) - 1.0) < 1e-4
    assert not np.isnan(vec).any()
    assert not np.isinf(vec).any()
    print("  ✅ test_sbert_encoder_loading_and_shape PASSED")


# ─────────────────────────────────────────────────────────────────────────────
#  3. COSINE SIMILARITY ENGINE TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_cosine_similarity_identical():
    vec = np.array([0.5, 0.5, 0.5, 0.5], dtype=np.float32)
    sim = SimilarityEngine.cosine_similarity(vec, vec)
    assert abs(sim - 1.0) < 1e-5
    print("  ✅ test_cosine_similarity_identical PASSED")


def test_cosine_similarity_orthogonal():
    vec_a = np.array([1.0, 0.0, 0.0], dtype=np.float32)
    vec_b = np.array([0.0, 1.0, 0.0], dtype=np.float32)
    sim = SimilarityEngine.cosine_similarity(vec_a, vec_b)
    assert abs(sim - 0.0) < 1e-5
    print("  ✅ test_cosine_similarity_orthogonal PASSED")


def test_cosine_similarity_dimension_mismatch():
    vec_a = np.array([1.0, 2.0, 3.0], dtype=np.float32)
    vec_b = np.array([1.0, 2.0], dtype=np.float32)
    try:
        SimilarityEngine.cosine_similarity(vec_a, vec_b)
        assert False, "Should have raised ValueError for dimension mismatch"
    except ValueError:
        print("  ✅ test_cosine_similarity_dimension_mismatch PASSED")


def test_batch_cosine_similarity():
    student_vec = np.array([1.0, 0.0], dtype=np.float32)
    mentor_matrix = np.array([
        [1.0, 0.0],  # identical -> 1.0
        [0.0, 1.0],  # orthogonal -> 0.0
        [0.7071, 0.7071],  # 45 deg -> ~0.7071
    ], dtype=np.float32)
    sims = SimilarityEngine.batch_cosine_similarity(student_vec, mentor_matrix)
    assert len(sims) == 3
    assert abs(sims[0] - 1.0) < 1e-4
    assert abs(sims[1] - 0.0) < 1e-4
    assert abs(sims[2] - 0.7071) < 1e-3
    print("  ✅ test_batch_cosine_similarity PASSED")


def test_similarity_to_percentage():
    pct1 = SimilarityEngine.similarity_to_percentage(0.8421)
    assert pct1 == 84.2
    pct2 = SimilarityEngine.similarity_to_percentage(-0.5)
    assert pct2 == 0.0
    print("  ✅ test_similarity_to_percentage PASSED")


# ─────────────────────────────────────────────────────────────────────────────
#  4. MENTOR RANKER TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_ranker_sorting_and_top_k():
    student = make_student_a()
    mentors = make_mentors()
    scores = [0.45, 0.92, 0.31]  # mentor 1 = 0.92 (highest)

    results = MentorRanker.rank_mentors(student, mentors, scores, top_k=2)
    assert len(results) == 2
    assert results[0].mentor.name == "Mentor Beta (AI/ML)"
    assert results[0].rank == 1
    assert results[0].similarity_score == 0.92
    assert results[1].mentor.name == "Mentor Alpha (Mobile)"
    assert results[1].rank == 2
    print("  ✅ test_ranker_sorting_and_top_k PASSED")


def test_ranker_top_k_exceeds_pool():
    student = make_student_a()
    mentors = make_mentors()
    scores = [0.5, 0.8, 0.3]

    results = MentorRanker.rank_mentors(student, mentors, scores, top_k=10)
    assert len(results) == 3, "Should return all available mentors when top_k > len(mentors)"
    print("  ✅ test_ranker_top_k_exceeds_pool PASSED")


def test_ranker_invalid_top_k():
    student = make_student_a()
    mentors = make_mentors()
    scores = [0.5, 0.8, 0.3]

    try:
        MentorRanker.rank_mentors(student, mentors, scores, top_k=0)
        assert False, "Should raise ValueError for top_k <= 0"
    except ValueError:
        print("  ✅ test_ranker_invalid_top_k PASSED")


def test_skill_overlap():
    student_skills = ["python", "pytorch", "sql"]
    mentor_skills = ["Python", "PyTorch", "Docker", "AWS"]
    overlap = MentorRanker.compute_skill_overlap(student_skills, mentor_skills)
    assert overlap == ["python", "pytorch"]
    print("  ✅ test_skill_overlap PASSED")


# ─────────────────────────────────────────────────────────────────────────────
#  5. END-TO-END PIPELINE & SEMANTIC DIFFERENTIATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

def test_semantic_matching_differentiation():
    """Verify Student A (AI) and Student B (Web) receive distinct top matches."""
    student_a = make_student_a()
    student_b = make_student_b()
    mentors = make_mentors()

    results_a = MentorMatchEngine.match_student(student_a, mentors, top_k=3)
    results_b = MentorMatchEngine.match_student(student_b, mentors, top_k=3)

    assert len(results_a) == 3
    assert len(results_b) == 3

    # Student A (AI/ML focus) should match Mentor Beta (AI/ML) as #1
    assert results_a[0].mentor.mentor_id == "M002"
    assert "AI" in results_a[0].mentor.career_domain

    # Student B (Full Stack Web focus) should match Mentor Gamma (Web) as #1
    assert results_b[0].mentor.mentor_id == "M003"
    assert "Web" in results_b[0].mentor.career_domain

    # Confirm different top mentors for different student goals
    assert results_a[0].mentor.mentor_id != results_b[0].mentor.mentor_id
    print("  ✅ test_semantic_matching_differentiation PASSED")


def test_full_pipeline_with_sample_json():
    """Test full pipeline using bundled 10 sample mentors."""
    student_a = make_student_a()
    mentors = MentorMatchEngine.load_sample_mentors()
    assert len(mentors) == 10

    results = MentorMatchEngine.match_student(student_a, mentors, top_k=5)
    assert len(results) == 5
    assert results[0].rank == 1
    assert results[0].similarity_score >= results[1].similarity_score
    assert results[1].similarity_score >= results[2].similarity_score
    print("  ✅ test_full_pipeline_with_sample_json PASSED")


# ─────────────────────────────────────────────────────────────────────────────
#  TEST RUNNER
# ─────────────────────────────────────────────────────────────────────────────

ALL_TESTS = [
    test_student_profile_creation,
    test_mentor_profile_creation,
    test_match_result_to_dict,
    test_build_profile_text,
    test_sbert_encoder_loading_and_shape,
    test_cosine_similarity_identical,
    test_cosine_similarity_orthogonal,
    test_cosine_similarity_dimension_mismatch,
    test_batch_cosine_similarity,
    test_similarity_to_percentage,
    test_ranker_sorting_and_top_k,
    test_ranker_top_k_exceeds_pool,
    test_ranker_invalid_top_k,
    test_skill_overlap,
    test_semantic_matching_differentiation,
    test_full_pipeline_with_sample_json,
]


if __name__ == "__main__":
    print("\n🧠 Mentor Match Engine — STEP 4 Test Suite")
    print("=" * 65)

    passed = 0
    failed = 0
    for test_fn in ALL_TESTS:
        try:
            test_fn()
            passed += 1
        except Exception as err:
            failed += 1
            print(f"  ❌ {test_fn.__name__} FAILED: {err}")

    print("\n" + "=" * 65)
    print(f"Results: {passed} passed, {failed} failed out of {len(ALL_TESTS)} total")
    if failed == 0:
        print("✅ All Step 4 tests passed successfully!")
    else:
        print(f"⚠️ {failed} test(s) failed.")
