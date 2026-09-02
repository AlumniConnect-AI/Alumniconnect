"""
Career Twin Engine — Streamlit Interactive UI
=============================================
Run: streamlit run app.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

import json
import streamlit as st

from career_twin.engine import CareerTwinEngine
from career_twin.nlp_parser import NLPParser
from tests.test_engine import SAMPLE_PROFILES, SAMPLE_JDS

# ─── Page Config ─────────────────────────────────────────────────────────────
st.set_page_config(
    page_title  = "Career Twin Engine",
    page_icon   = "🧬",
    layout      = "wide",
    initial_sidebar_state = "expanded"
)

# ─── CSS Styling ─────────────────────────────────────────────────────────────
st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
html, body, [class*="css"] { font-family: 'Inter', sans-serif; }

.main-header {
    background: linear-gradient(135deg, #0F0C29, #302B63, #24243E);
    border-radius: 16px;
    padding: 2rem 2.5rem;
    margin-bottom: 2rem;
    text-align: center;
}
.main-header h1 { color: #ffffff !important; font-size: 2.4rem; font-weight: 700; margin: 0; }
.main-header p  { color: #c3bef7 !important; font-size: 1.05rem; margin-top: 0.5rem; }

.score-card {
    background: linear-gradient(135deg, #1a1a2e, #16213e);
    border: 1px solid #0f3460;
    border-radius: 16px;
    padding: 1.5rem;
    text-align: center;
    color: #ffffff;
}
.score-number { font-size: 3.5rem; font-weight: 700; color: #a78bfa; }
.score-tier   { font-size: 1.2rem; font-weight: 500; color: #e2d9f3; margin-top: 0.2rem; }

.metric-row {
    display: flex; gap: 12px; flex-wrap: wrap; margin: 1.2rem 0;
}
.metric-box {
    flex: 1; min-width: 120px;
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 12px;
    padding: 0.8rem;
    text-align: center;
}
.metric-box .label { color: #9ca3af !important; font-size: 0.75rem; text-transform: uppercase; }
.metric-box .value { color: #a78bfa !important; font-size: 1.4rem; font-weight: 700; }

.tag {
    display: inline-block;
    padding: 5px 14px;
    border-radius: 20px;
    font-size: 0.85rem;
    font-weight: 600;
    margin: 4px;
}
.tag-green  { background: #064e3b; color: #a7f3d0 !important; border: 1px solid #059669; }
.tag-red    { background: #7f1d1d; color: #fecaca !important; border: 1px solid #dc2626; }
.tag-blue   { background: #1e3a8a; color: #bfdbfe !important; border: 1px solid #2563eb; }
.tag-purple { background: #4c1d95; color: #ddd6fe !important; border: 1px solid #7c3aed; }

.section-title {
    font-size: 1.05rem; font-weight: 600; color: #f3f4f6 !important;
    border-left: 4px solid #7c3aed;
    padding-left: 10px;
    margin: 1.2rem 0 0.7rem 0;
}
.rec-card {
    background: #1f1b3a;
    border-left: 4px solid #8b5cf6;
    border-radius: 8px;
    padding: 0.75rem 1rem;
    margin: 8px 0;
    font-size: 0.92rem;
    color: #f3f4f6 !important;
}
.role-card {
    background: #1e1e38;
    border: 1px solid #3b3b6d;
    border-radius: 10px;
    padding: 0.75rem 1.1rem;
    margin: 8px 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.role-card .role-name {
    font-weight: 600;
    color: #ffffff !important;
    font-size: 0.95rem;
}
.role-card .role-pct {
    font-weight: 700;
    color: #c4b5fd !important;
    font-size: 1.05rem;
    background: rgba(167, 139, 250, 0.2);
    padding: 3px 10px;
    border-radius: 12px;
}
</style>
""", unsafe_allow_html=True)

# ─── Header ──────────────────────────────────────────────────────────────────
st.markdown("""
<div class="main-header">
  <h1>🧬 Career Twin Engine</h1>
  <p>AI-powered Career Matching · Skill Analysis · Role Recommendations</p>
</div>
""", unsafe_allow_html=True)

# ─── Initialize Session State with Default Sample Data ───────────────────────
if "profile_input" not in st.session_state or not st.session_state["profile_input"]:
    st.session_state["profile_input"] = SAMPLE_PROFILES["mobile_dev"]
if "jd_input" not in st.session_state or not st.session_state["jd_input"]:
    st.session_state["jd_input"] = SAMPLE_JDS["flutter_jd"]
if "req_exp_input" not in st.session_state or st.session_state["req_exp_input"] <= 0:
    st.session_state["req_exp_input"] = 2.0

def update_sample_data():
    p_key = st.session_state.get("select_p_key", "mobile_dev")
    j_key = st.session_state.get("select_j_key", "flutter_jd")
    st.session_state["profile_input"] = SAMPLE_PROFILES[p_key]
    st.session_state["jd_input"] = SAMPLE_JDS[j_key]
    auto_exp = NLPParser.extract_experience_years(SAMPLE_JDS[j_key])
    st.session_state["req_exp_input"] = float(auto_exp if auto_exp > 0 else 1.0)

# ─── Sidebar — Load Samples ───────────────────────────────────────────────────
with st.sidebar:
    st.markdown("### ⚡ Quick Load Samples")
    sample_profile_key = st.selectbox(
        "Choose a sample profile:",
        list(SAMPLE_PROFILES.keys()),
        key="select_p_key",
        format_func=lambda x: x.replace("_", " ").title(),
        on_change=update_sample_data
    )
    sample_jd_key = st.selectbox(
        "Choose a sample JD:",
        list(SAMPLE_JDS.keys()),
        key="select_j_key",
        format_func=lambda x: x.replace("_", " ").title(),
        on_change=update_sample_data
    )
    if st.button("📥 Load Sample Data", use_container_width=True, on_click=update_sample_data):
        st.toast("Loaded sample profile & JD data!", icon="📥")

    st.divider()
    st.markdown("### ℹ️ About")
    st.markdown("""
This module is part of the **AlumniConnect** AI platform.
It analyzes candidate profiles against job descriptions using:
- **NLP** keyword & skill extraction
- **TF-IDF Semantic Similarity**
- **Weighted Career Scoring**
- **Role Fingerprinting**

> Fully standalone — no backend connection required.
    """)

# ─── Input columns ──────────────────────────────────────────────────────────
col_a, col_b = st.columns(2, gap="large")

with col_a:
    st.markdown("#### 📋 Candidate Profile / Resume (CD)")
    profile_text = st.text_area(
        label       = "Paste your resume or profile text here",
        key         = "profile_input",
        height      = 320,
        placeholder = "Paste resume or profile here...",
        label_visibility = "collapsed"
    )

with col_b:
    st.markdown("#### 💼 Job Description (JD)")
    jd_text = st.text_area(
        label       = "Paste the job description here",
        key         = "jd_input",
        height      = 320,
        placeholder = "Paste job description here...",
        label_visibility = "collapsed"
    )

req_exp = st.number_input(
    "⏱ Required Experience (years stated in JD)",
    key       = "req_exp_input",
    min_value = 0.0,
    max_value = 20.0,
    step      = 0.5
)

run_btn = st.button("🚀 Analyze Career Match", type="primary", use_container_width=True)

# ─── Analysis & Results ──────────────────────────────────────────────────────
if run_btn:
    if not profile_text.strip() or not jd_text.strip():
        st.error("⚠️ Please provide both a profile and a job description.")
    else:
        with st.spinner("🧠 Analyzing candidate profile & job description..."):
            result = CareerTwinEngine.analyze(profile_text, jd_text, req_exp)

        cs = result["career_score"]
        sp = result["skill_profile"]
        pp = result["parsed_profile"]
        pj = result["parsed_jd"]

        st.markdown("---")
        st.markdown("## 📊 Results & Input Overview")

        # --- Visible CD and JD Input Summary ---
        with st.expander("📄 View Analyzed Candidate Data (CD) & Job Description (JD)", expanded=True):
            cd_col, jd_col = st.columns(2, gap="medium")
            with cd_col:
                st.markdown("**📋 Candidate Profile (CD)**")
                st.text_area("CD Text", value=profile_text, height=180, disabled=True, key="res_cd_view")
            with jd_col:
                st.markdown("**💼 Job Description (JD)**")
                st.text_area("JD Text", value=jd_text, height=180, disabled=True, key="res_jd_view")

        # --- Career Score Card ---
        score_color = (
            "#22c55e" if cs["career_score"] >= 70 else
            "#f59e0b" if cs["career_score"] >= 50 else "#ef4444"
        )
        st.markdown(f"""
        <div class="score-card">
          <div class="score-number" style="color:{score_color}">
            {cs['career_score']}<span style="font-size:1.5rem;color:#9ca3af">/100</span>
          </div>
          <div class="score-tier">{cs['tier']}</div>
          <div class="metric-row" style="margin-top:1.5rem;">
            <div class="metric-box">
              <div class="label">Skill Match</div>
              <div class="value">{cs['skill_score']}%</div>
            </div>
            <div class="metric-box">
              <div class="label">Semantic</div>
              <div class="value">{cs['semantic_score']}%</div>
            </div>
            <div class="metric-box">
              <div class="label">Experience</div>
              <div class="value">{cs['experience_score']}%</div>
            </div>
            <div class="metric-box">
              <div class="label">Education</div>
              <div class="value">{cs['education_score']}%</div>
            </div>
          </div>
        </div>
        """, unsafe_allow_html=True)

        st.markdown("<br>", unsafe_allow_html=True)

        res_col1, res_col2 = st.columns([1.1, 0.9], gap="large")

        with res_col1:
            # Skill coverage gauge
            st.markdown("### 🎯 Skill Analysis")
            st.progress(int(sp["skill_coverage_%"]), text=f"Skill Coverage: {sp['skill_coverage_%']}%")

            # Matched Skills
            st.markdown('<div class="section-title">✅ Matched Skills</div>', unsafe_allow_html=True)
            if sp["matched_skills"]:
                tags = " ".join([f'<span class="tag tag-green">{s}</span>' for s in sp["matched_skills"]])
                st.markdown(tags, unsafe_allow_html=True)
            else:
                st.caption("No matching skills found.")

            # Missing Skills
            st.markdown('<div class="section-title">❌ Missing Skills</div>', unsafe_allow_html=True)
            if sp["missing_skills"]:
                tags = " ".join([f'<span class="tag tag-red">{s}</span>' for s in sp["missing_skills"]])
                st.markdown(tags, unsafe_allow_html=True)
            else:
                st.success("You have all the required skills!")

            # Strengths
            st.markdown('<div class="section-title">✨ Your Extra Strengths</div>', unsafe_allow_html=True)
            if sp["skill_strengths"]:
                tags = " ".join([f'<span class="tag tag-blue">{s}</span>' for s in sp["skill_strengths"]])
                st.markdown(tags, unsafe_allow_html=True)
            else:
                st.caption("No extra skills beyond the JD found.")

        with res_col2:
            # Suggested Roles
            st.markdown("### 🔮 Best-Fit Career Roles")
            if sp["suggested_roles"]:
                for role_item in sp["suggested_roles"]:
                    st.markdown(f"""
                    <div class="role-card">
                      <span class="role-name">{role_item['role']}</span>
                      <span class="role-pct">{role_item['match_percent']}%</span>
                    </div>
                    """, unsafe_allow_html=True)
            else:
                st.info("Not enough skills to suggest a role. Add more skills to your profile.")

            # Recommendations
            st.markdown("### 💡 AI Recommendations")
            for rec in sp["recommendations"]:
                st.markdown(f'<div class="rec-card">{rec}</div>', unsafe_allow_html=True)

            # Learning Resources
            if sp["learning_resources"]:
                st.markdown("### 📚 Upskilling Resources")
                for res in sp["learning_resources"]:
                    st.markdown(f"- **{res['skill'].title()}**: [{res['resource']}]({res['resource']})")

        # --- Parsed Metadata Expander ---
        with st.expander("🔬 View Raw Parsed Data (NLP Extraction)"):
            meta_c1, meta_c2 = st.columns(2)
            with meta_c1:
                st.markdown("**Candidate Profile (parsed)**")
                st.json(pp)
            with meta_c2:
                st.markdown("**Job Description (parsed)**")
                st.json(pj)

        with st.expander("📤 Export Full Result as JSON"):
            st.code(json.dumps(result, indent=2), language="json")
