"""
Sample data and test cases for the Career Twin Engine.
Run: python -m pytest tests/test_engine.py -v
  OR: python tests/test_engine.py
"""

# ─────────────────────────────────────────────────────────────────────────────
# SAMPLE INPUTS
# ─────────────────────────────────────────────────────────────────────────────

SAMPLE_PROFILES = {
    "mobile_dev": """
        Alagu Aadithan A
        Bachelor of Computer Applications (BCA) — 2024
        Flutter Developer | 2 years of experience

        Skills:
          • Flutter, Dart, Firebase, Supabase, Git, GitHub
          • REST APIs, Provider (state management)
          • Android, iOS deployment
          • Communication, Teamwork, Agile

        Projects:
          1. AlumniConnect – Mobile networking app (Flutter + Firebase + Supabase)
          2. EventHub – Campus event scheduling app with QR check-in
          3. ChatSync – Real-time chat with image/PDF sharing

        Experience:
          Freelance Flutter Developer (2022–2024)
          Built and deployed 5+ mobile applications for clients.
    """,

    "data_scientist": """
        Priya Suresh
        M.Tech in Data Science — IIT Madras — 2022
        Data Scientist with 4 years of experience

        Technical Skills:
          Python, Machine Learning, Deep Learning, NLP, scikit-learn, TensorFlow,
          PyTorch, Pandas, NumPy, SQL, PostgreSQL, Git, Docker

        Projects:
          - Sentiment Analysis engine for e-commerce product reviews (NLP)
          - Churn prediction model (XGBoost, scikit-learn)
          - Image classification pipeline (CNN, TensorFlow)

        Soft Skills: Leadership, Communication, Problem Solving, Analytical
    """,

    "fresh_grad": """
        Ravi Kumar
        B.Tech in Computer Science — 2025 (fresher)

        Skills: Python, HTML, CSS, JavaScript, React, Git, MySQL
        Soft Skills: Teamwork, Communication

        Projects:
          1. E-commerce website (HTML, CSS, JS)
          2. Student portal (React + MySQL)
    """,
}

SAMPLE_JDS = {
    "flutter_jd": """
        Job Title: Flutter Developer
        Experience Required: 1-3 years

        Requirements:
          • Proficiency in Flutter and Dart
          • Experience with Firebase (Authentication, Firestore)
          • Supabase for cloud storage preferred
          • Knowledge of REST API integration
          • Familiarity with Git and version control
          • Android/iOS deployment experience
          • Good communication and teamwork skills
    """,

    "ml_engineer_jd": """
        Job Title: Machine Learning Engineer
        Experience Required: 3+ years

        Requirements:
          - Strong programming skills in Python
          - Hands-on experience with Machine Learning and Deep Learning
          - NLP experience preferred
          - Familiarity with TensorFlow or PyTorch
          - scikit-learn for classical ML
          - Docker for model containerization
          - PostgreSQL or MongoDB experience
          - Git version control
          - Strong problem solving and analytical thinking
    """,

    "frontend_jd": """
        Job Title: Frontend Developer
        Experience Required: 1-2 years

        Requirements:
          HTML5, CSS3, JavaScript (ES6+), React.js
          Familiar with Git, REST APIs
          Good communication and teamwork
    """,
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASES
# ─────────────────────────────────────────────────────────────────────────────

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from career_twin.engine import CareerTwinEngine


def run_test(name, profile_text, jd_text, required_exp, expected_min_score=None):
    print(f"\n{'='*60}")
    print(f"  TEST: {name}")
    print(f"{'='*60}")
    result = CareerTwinEngine.analyze(profile_text, jd_text, required_exp)

    cs  = result["career_score"]
    sp  = result["skill_profile"]
    pp  = result["parsed_profile"]

    print(f"\n📊 Career Score     : {cs['career_score']} / 100  →  {cs['tier']}")
    print(f"   Skill Score      : {cs['skill_score']}%")
    print(f"   Semantic Score   : {cs['semantic_score']}%")
    print(f"   Experience Score : {cs['experience_score']}%")
    print(f"   Education Score  : {cs['education_score']}%")

    print(f"\n🎯 Matched Skills  : {sp['matched_skills']}")
    print(f"❌ Missing Skills  : {sp['missing_skills']}")
    print(f"✨ Skill Strengths : {sp['skill_strengths']}")
    print(f"📈 Skill Coverage  : {sp['skill_coverage_%']}%")

    print(f"\n🔮 Suggested Roles :")
    for r in sp["suggested_roles"]:
        print(f"   → {r['role']}  ({r['match_percent']}% match)")

    print(f"\n💡 Recommendations :")
    for rec in sp["recommendations"]:
        print(f"   {rec}")

    print(f"\n📚 Learning Resources :")
    for res in sp["learning_resources"]:
        print(f"   • {res['skill']}: {res['resource']}")

    # Assertion
    if expected_min_score is not None:
        assert cs["career_score"] >= expected_min_score, (
            f"❌ FAIL: Expected score >= {expected_min_score}, got {cs['career_score']}"
        )
        print(f"\n✅ PASS: Score {cs['career_score']} >= {expected_min_score}")

    return result


def test_strong_flutter_dev():
    return run_test(
        name             = "Strong Flutter Dev vs Flutter JD",
        profile_text     = SAMPLE_PROFILES["mobile_dev"],
        jd_text          = SAMPLE_JDS["flutter_jd"],
        required_exp     = 2.0,
        expected_min_score = 60,
    )


def test_data_scientist_vs_ml_jd():
    return run_test(
        name             = "Senior Data Scientist vs ML Engineer JD",
        profile_text     = SAMPLE_PROFILES["data_scientist"],
        jd_text          = SAMPLE_JDS["ml_engineer_jd"],
        required_exp     = 3.0,
        expected_min_score = 60,
    )


def test_fresh_grad_vs_frontend_jd():
    return run_test(
        name             = "Fresh Grad vs Frontend Developer JD",
        profile_text     = SAMPLE_PROFILES["fresh_grad"],
        jd_text          = SAMPLE_JDS["frontend_jd"],
        required_exp     = 1.0,
        expected_min_score = 30,
    )


def test_mismatch():
    """Candidate with only mobile skills vs ML JD → expect low score."""
    return run_test(
        name             = "Mismatch: Mobile Dev vs ML JD",
        profile_text     = SAMPLE_PROFILES["mobile_dev"],
        jd_text          = SAMPLE_JDS["ml_engineer_jd"],
        required_exp     = 3.0,
        expected_min_score = None,   # no assertion, just observe
    )


if __name__ == "__main__":
    print("\n🚀  Career Twin Engine — Test Suite")
    print("=" * 60)
    test_strong_flutter_dev()
    test_data_scientist_vs_ml_jd()
    test_fresh_grad_vs_frontend_jd()
    test_mismatch()
    print("\n\n✅ All tests completed.")
