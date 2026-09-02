"""
Mentor Match Engine — Streamlit Interactive Web Interface
============================================================
Run:
    streamlit run mentor_match_app.py
"""

import os
import sys
import json
import streamlit as st

# Add ai-module directory to sys.path
sys.path.insert(0, os.path.dirname(__file__))

from mentor_match_engine.models import StudentProfile
from mentor_match_engine.engine import MentorMatchEngine
from mentor_match_engine.profile_encoder import DEFAULT_MODEL_NAME

# ─── Page Config ─────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Mentor Match Engine — SBERT AI Recommendations",
    page_icon="🧠",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ─── Custom CSS Styling ───────────────────────────────────────────────────────
st.markdown(
    """
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
html, body, [class*="css"] { font-family: 'Inter', sans-serif; }

.main-header {
    background: linear-gradient(135deg, #0d1b2a, #1b263b, #415a77);
    border: 1px solid #778da9;
    border-radius: 18px;
    padding: 2rem 2.5rem;
    margin-bottom: 2rem;
    text-align: center;
    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
}
.main-header h1 {
    color: #ffffff !important;
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0;
    letter-spacing: -0.5px;
}
.main-header p {
    color: #e0e1dd !important;
    font-size: 1.1rem;
    margin-top: 0.6rem;
}

.mentor-card {
    background: linear-gradient(135deg, #1e1e38, #16162a);
    border: 1px solid #3b3b6d;
    border-radius: 16px;
    padding: 1.5rem;
    margin-bottom: 1.2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
    transition: transform 0.2s ease, border-color 0.2s ease;
}
.mentor-card:hover {
    border-color: #8b5cf6;
}

.rank-badge {
    display: inline-block;
    background: linear-gradient(135deg, #7c3aed, #4c1d95);
    color: #ffffff !important;
    font-weight: 700;
    font-size: 0.9rem;
    padding: 4px 14px;
    border-radius: 20px;
    margin-bottom: 0.8rem;
}

.score-badge {
    background: rgba(139, 92, 246, 0.15);
    border: 1px solid #8b5cf6;
    color: #c4b5fd !important;
    font-weight: 700;
    font-size: 1.2rem;
    padding: 6px 16px;
    border-radius: 12px;
    float: right;
}

.tag-skill {
    display: inline-block;
    background: #064e3b;
    color: #a7f3d0 !important;
    border: 1px solid #059669;
    padding: 4px 12px;
    border-radius: 16px;
    font-size: 0.82rem;
    font-weight: 600;
    margin: 3px;
}

.reason-item {
    color: #e2e8f0 !important;
    font-size: 0.92rem;
    margin: 4px 0;
}
</style>
""",
    unsafe_allow_html=True,
)

# ─── Header ──────────────────────────────────────────────────────────────────
st.markdown(
    """
<div class="main-header">
  <h1>🧠 Mentor Match Engine</h1>
  <p>SBERT Profile Embeddings (384-D) · Vector Cosine Similarity · Top-K Alumni Mentor Recommendations</p>
</div>
""",
    unsafe_allow_html=True,
)

# ─── Sidebar Controls ────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("### 🎛 Control Panel")

    preset_option = st.selectbox(
        "Select Student Preset:",
        [
            "Student A: AI & Machine Learning",
            "Student B: Full Stack Web Development",
            "Student C: Mobile App Developer (Flutter/Dart)",
            "Custom Profile Input",
        ],
    )

    top_k_val = st.slider("Number of Top Matches (Top-K):", min_value=1, max_value=10, value=5)

    st.divider()

    st.markdown("### 📊 Engine Status")
    st.markdown(f"**Model:** `{DEFAULT_MODEL_NAME}`")
    st.markdown("**Vector Dim:** `384`")
    st.markdown("**Normalization:** `L2 Unit Norm`")
    st.markdown("**Metric:** `Cosine Similarity`")

    st.divider()
    st.info("Isolated module built for AlumniConnect.")

# ─── Student Profile Construction ─────────────────────────────────────────────
if preset_option == "Student A: AI & Machine Learning":
    default_name = "Alagu Aadithan (Student A)"
    default_dept = "Computer Science"
    default_skills = "python, machine learning, pytorch, deep learning, sql"
    default_interests = "artificial intelligence, computer vision, neural networks"
    default_goal = "Seeking a career as an AI / Machine Learning Engineer"
    default_bio = "Final year student focused on deep learning models, NLP, and computer vision algorithms."
elif preset_option == "Student B: Full Stack Web Development":
    default_name = "Priya Sharma (Student B)"
    default_dept = "Information Technology"
    default_skills = "react, javascript, node.js, html, css, typescript, mongodb"
    default_interests = "full stack web development, cloud computing, REST APIs"
    default_goal = "Aspiring Full Stack Web Developer building scalable cloud applications"
    default_bio = "IT undergraduate building web applications with MERN stack and cloud hosting."
elif preset_option == "Student C: Mobile App Developer (Flutter/Dart)":
    default_name = "Karthik Raja (Student C)"
    default_dept = "Computer Science"
    default_skills = "flutter, dart, firebase, mobile development, android, git"
    default_interests = "cross-platform mobile apps, UI/UX design, real-time sync"
    default_goal = "Seeking a Mobile Developer role building Flutter iOS and Android applications"
    default_bio = "Passionate mobile developer creating smooth cross-platform experiences using Flutter and Firebase."
else:
    default_name = "Custom Student"
    default_dept = "Computer Science"
    default_skills = "python, java, sql"
    default_interests = "software engineering"
    default_goal = "Software Engineer"
    default_bio = "Dedicated computer science student seeking mentorship."

# Input Form
st.markdown("### 🎓 Student Profile Setup")

col_p1, col_p2 = st.columns([1, 1], gap="medium")

with col_p1:
    s_name = st.text_input("Student Name:", value=default_name)
    s_dept = st.text_input("Department:", value=default_dept)
    s_skills_str = st.text_area("Technical Skills (comma-separated):", value=default_skills, height=90)

with col_p2:
    s_goal = st.text_input("Career Goal / Target Role:", value=default_goal)
    s_interests_str = st.text_input("Interests & Specializations (comma-separated):", value=default_interests)
    s_bio = st.text_area("Profile Summary / Bio:", value=default_bio, height=90)

skills_list = [s.strip() for s in s_skills_str.split(",") if s.strip()]
interests_list = [i.strip() for i in s_interests_str.split(",") if i.strip()]

current_student = StudentProfile(
    student_id="STU_UI_01",
    name=s_name,
    department=s_dept,
    skills=skills_list,
    interests=interests_list,
    career_goals=s_goal,
    bio=s_bio,
    education=f"B.Tech {s_dept} — 2025",
    experience_years=1.0,
)

st.markdown("<br>", unsafe_allow_html=True)
match_btn = st.button("🚀 Find Matching Alumni Mentors", type="primary", use_container_width=True)

# ─── Execution & Results ──────────────────────────────────────────────────────
if match_btn or preset_option:
    st.divider()
    st.markdown(f"## 🏆 Top {top_k_val} Recommended Alumni Mentors")

    with st.spinner("🧠 Generating SBERT embeddings & computing vector Cosine Similarities..."):
        mentors_pool = MentorMatchEngine.load_sample_mentors()
        results = MentorMatchEngine.match_student(current_student, mentors_pool, top_k=top_k_val)

    # Display Metrics Summary
    m_col1, m_col2, m_col3, m_col4 = st.columns(4)
    with m_col1:
        st.metric("Mentors Evaluated", len(mentors_pool))
    with m_col2:
        st.metric("SBERT Vector Dim", "384")
    with m_col3:
        st.metric("Top Match Score", f"{results[0].match_percentage}%")
    with m_col4:
        st.metric("Top Match Mentor", results[0].mentor.name)

    st.markdown("<br>", unsafe_allow_html=True)

    # Render Mentor Cards
    for res in results:
        m = res.mentor
        card_html = f"""
        <div class="mentor-card">
            <span class="score-badge">{res.match_percentage}% Match</span>
            <span class="rank-badge">RANK #{res.rank}</span>
            <h3 style="color:#ffffff; margin:0.2rem 0;">{m.name}</h3>
            <p style="color:#a78bfa; margin-bottom:0.8rem; font-weight:600;">
                💼 {m.current_role} at {m.company} &nbsp;|&nbsp; 🏫 {m.department} Alumni ({m.experience_years:.0f} yrs exp)
            </p>
            <p style="color:#cbd5e1; font-size:0.9rem;">
                <b>Domain:</b> {m.career_domain} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Raw Cosine Similarity:</b> <code>{res.similarity_score:.4f}</code>
            </p>
            <div style="margin: 0.8rem 0;">
        """
        st.markdown(card_html, unsafe_allow_html=True)

        if res.matched_skills:
            st.markdown("**🎯 Overlapping Technical Skills:**")
            tags = " ".join([f'<span class="tag-skill">{s}</span>' for s in res.matched_skills])
            st.markdown(tags, unsafe_allow_html=True)

        st.markdown("**💡 Match Insights & Reasons:**")
        for reason in res.match_reasons:
            st.markdown(f'<div class="reason-item">• {reason}</div>', unsafe_allow_html=True)

        st.markdown("---")

    # Raw Json Data Expander
    with st.expander("🔬 View Raw Match Payload (JSON)"):
        st.json([r.to_dict() for r in results])
