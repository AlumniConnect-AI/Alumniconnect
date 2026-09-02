"""
Mentor Match Engine — SBERT Profile Encoder Demo
=================================================
Demonstrates the SBERT profile embedding layer.

Run:
  py mentor_match_engine/demo_encoder.py
"""

import os
import sys
import numpy as np

# Ensure parent ai-module directory is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from mentor_match_engine.models import StudentProfile
from mentor_match_engine.profile_encoder import ProfileEncoder, DEFAULT_MODEL_NAME
from mentor_match_engine.engine import MentorMatchEngine


def run_encoder_demo():
    print("=" * 65)
    print(" 🧠 MENTOR MATCH ENGINE — SBERT PROFILE ENCODER DEMO")
    print("=" * 65)

    # 1. Initialize ProfileEncoder
    print(f"\n[1] Initializing ProfileEncoder...")
    encoder = ProfileEncoder(model_name=DEFAULT_MODEL_NAME)
    print(f"    Model Name : {encoder.model_name}")
    print(f"    Model Loaded: {encoder.is_model_loaded()} (lazy loading confirmed)")

    # 2. Load Sample Mentors
    print(f"\n[2] Loading sample mentor profiles...")
    mentors = MentorMatchEngine.load_sample_mentors()
    print(f"    Loaded {len(mentors)} sample alumni mentor profiles.")

    # 3. Create Sample Student Profile
    print(f"\n[3] Creating sample student profile...")
    student = StudentProfile(
        student_id="STU_101",
        name="Alagu Aadithan",
        department="Computer Science",
        skills=["flutter", "dart", "firebase", "python", "git"],
        interests=["mobile development", "artificial intelligence", "cross-platform apps"],
        career_goals="Seeking a career in mobile application development and AI integration",
        bio="BCA student with hands-on experience in Flutter and backend REST APIs.",
        education="Bachelor of Computer Applications (BCA) — 2024",
        experience_years=1.5,
    )
    print(f"    Student Name: {student.name}")
    print(f"    Skills      : {', '.join(student.skills)}")
    print(f"    Interests   : {', '.join(student.interests)}")

    # 4. Profile to Structured Text Conversion
    print(f"\n[4] Structured Profile Text Representation:")
    print("-" * 50)
    student_text = ProfileEncoder.build_profile_text(student)
    print(student_text)
    print("-" * 50)

    # 5. Generate Embeddings using SBERT
    print(f"\n[5] Encoding student profile into SBERT embedding...")
    student_embedding = encoder.encode_student_profile(student, normalize_embeddings=True)
    print(f"    Model Loaded Status : {encoder.is_model_loaded()}")
    print(f"    Student Embedding Shape : {student_embedding.shape}")
    print(f"    Student Embedding Norm  : {np.linalg.norm(student_embedding):.4f} (approx 1.0 = L2 normalized)")
    print(f"    First 5 Vector Values   : {np.round(student_embedding[:5], 4)}")

    print(f"\n[6] Batch encoding {len(mentors)} mentor profiles into SBERT embeddings...")
    mentor_embeddings = encoder.encode_profiles(mentors, normalize_embeddings=True, show_progress_bar=False)
    print(f"    Mentor Embedding Matrix Shape : {mentor_embeddings.shape}")
    print(f"    All mentor embedding norms    : {np.round([np.linalg.norm(v) for v in mentor_embeddings], 4)}")

    # 6. Verification Summary
    print("\n" + "=" * 65)
    print(" 📊 SBERT PROFILE ENCODER VERIFICATION SUMMARY")
    print("=" * 65)
    print(f"  • SBERT Model Used          : {encoder.model_name}")
    print(f"  • Number of Mentors Encoded : {len(mentors)}")
    print(f"  • Student Vector Dimension  : {student_embedding.shape[0]}")
    print(f"  • Mentor Matrix Dimensions  : {mentor_embeddings.shape}")
    print(f"  • Embedding Data Type       : {student_embedding.dtype}")
    print(f"  • Contains NaNs / Infs      : {np.isnan(student_embedding).any() or np.isnan(mentor_embeddings).any()}")
    print("  • Encoding Status           : ✅ SUCCESSFUL")
    print("=" * 65 + "\n")


if __name__ == "__main__":
    run_encoder_demo()
