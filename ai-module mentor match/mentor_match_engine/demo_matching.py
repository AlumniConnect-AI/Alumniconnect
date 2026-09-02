"""
Mentor Match Engine — End-to-End Semantic Matching Demo
=========================================================
Demonstrates semantic mentor recommendation using SBERT embeddings,
Cosine Similarity, and Mentor Ranking.

Tests two contrasting student profiles:
  - Student A: AI / Machine Learning Focus
  - Student B: Full Stack Web Development Focus

Run:
  py mentor_match_engine/demo_matching.py
"""

import os
import sys

# Ensure parent ai-module directory is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from mentor_match_engine.models import StudentProfile
from mentor_match_engine.engine import MentorMatchEngine


def print_student_recommendations(student: StudentProfile, top_k: int = 5):
    print("=" * 70)
    print(f" 🎓 STUDENT PROFILE: {student.name}")
    print("=" * 70)
    print(f"  • Department    : {student.department}")
    print(f"  • Skills        : {', '.join(student.skills)}")
    print(f"  • Interests     : {', '.join(student.interests)}")
    print(f"  • Career Goal   : {student.career_goals}")
    print(f"  • Bio           : {student.bio}")
    print("-" * 70)
    print(f" 🏆 TOP {top_k} ALUMNI MENTOR MATCHES (SBERT + Cosine Similarity):")
    print("-" * 70)

    mentors_pool = MentorMatchEngine.load_sample_mentors()
    results = MentorMatchEngine.match_student(student, mentors_pool, top_k=top_k)

    for res in results:
        print(f"\n  Rank #{res.rank}  |  {res.mentor.name}")
        print(f"  Role        : {res.mentor.current_role} at {res.mentor.company}")
        print(f"  Domain      : {res.mentor.career_domain}")
        print(f"  Similarity  : {res.similarity_score:.4f} (Raw Cosine Score)")
        print(f"  Match Score : {res.match_percentage}%")
        print(f"  Overlaps    : {', '.join(res.matched_skills) if res.matched_skills else 'Semantic profile alignment'}")
        print(f"  Key Reasons :")
        for reason in res.match_reasons:
            print(f"                • {reason}")

    print("\n" + "=" * 70 + "\n")
    return results


def run_demo():
    print("\n" + "═" * 70)
    print(" 🚀 MENTOR MATCH ENGINE — DEMO MATCHING EXECUTION")
    print("═" * 70 + "\n")

    # 1. Define Student A (AI / Machine Learning Focus)
    student_a = StudentProfile(
        student_id="STU_AI_01",
        name="Student A (AI / ML Focus)",
        department="Computer Science",
        skills=["python", "machine learning", "pytorch", "deep learning", "sql"],
        interests=["artificial intelligence", "computer vision", "neural networks"],
        career_goals="Seeking a career as an AI / Machine Learning Engineer building intelligent systems",
        bio="Final year Computer Science student specializing in deep learning algorithms and NLP.",
        education="B.Tech Computer Science — 2025",
        experience_years=1.0,
    )

    # 2. Define Student B (Full Stack Web Development Focus)
    student_b = StudentProfile(
        student_id="STU_WEB_02",
        name="Student B (Full Stack Web Focus)",
        department="Information Technology",
        skills=["react", "javascript", "node.js", "html", "css", "typescript", "mongodb"],
        interests=["full stack web development", "cloud computing", "user interface design"],
        career_goals="Aspiring Full Stack Web Developer building scalable cloud web applications",
        bio="Information Technology undergraduate building modern Web MERN stack applications.",
        education="B.Sc Information Technology — 2025",
        experience_years=1.0,
    )

    # 3. Run Matching for Student A
    results_a = print_student_recommendations(student_a, top_k=5)

    # 4. Run Matching for Student B
    results_b = print_student_recommendations(student_b, top_k=5)

    # 5. Summary Comparison
    print("═" * 70)
    print(" 📈 DYNAMIC RECOMMENDATION VERIFICATION SUMMARY")
    print("═" * 70)
    print(f"  • Student A Top Match : #{results_a[0].rank} {results_a[0].mentor.name} ({results_a[0].mentor.career_domain}) — {results_a[0].match_percentage}%")
    print(f"  • Student B Top Match : #{results_b[0].rank} {results_b[0].mentor.name} ({results_b[0].mentor.career_domain}) — {results_b[0].match_percentage}%")
    
    distinct = results_a[0].mentor.mentor_id != results_b[0].mentor.mentor_id
    print(f"  • Distinct Top Mentors Generated : {distinct} (Proves semantic differentiation)")
    print("═" * 70 + "\n")


if __name__ == "__main__":
    run_demo()
