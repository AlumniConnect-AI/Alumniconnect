# 🧬 Career Twin Engine — AI Module

An independent, modular AI system for career-profile matching, skill analysis, and role recommendations. Built for the **AlumniConnect** platform but fully standalone.

---

## 🗂️ Module Structure

```
ai-module/
├── career_twin/
│   ├── __init__.py        # Package entry point
│   ├── engine.py          # 🧠 Main orchestrator (public API)
│   ├── nlp_parser.py      # 📝 NLP extraction (skills, education, experience)
│   ├── matcher.py         # 🔗 TF-IDF semantic similarity & skill overlap
│   ├── scorer.py          # 📊 Weighted Career Score computation
│   └── skill_profiler.py  # 🎯 Skill profile + role recommendations
├── tests/
│   └── test_engine.py     # ✅ 4 test cases with sample input data
├── app.py                 # 🖥️ Streamlit interactive UI
├── run_tests.py           # Quick test runner
├── requirements.txt
└── README.md
```

---

## 🚀 Quick Start

```bash
cd ai-module
pip install -r requirements.txt

# Run all test cases
python run_tests.py

# Launch interactive UI
streamlit run app.py
```

---

## 🔌 Public API

```python
from career_twin.engine import CareerTwinEngine

result = CareerTwinEngine.analyze(
    profile_text              = "...",   # resume / profile text
    jd_text                   = "...",   # job description text
    required_experience_years = 2.0,     # years stated in job posting
)
```

### Output Structure

```json
{
  "parsed_profile": {
    "tech_skills": ["flutter", "dart", "firebase", "git"],
    "soft_skills": ["teamwork", "communication"],
    "experience_years": 2.0,
    "education": ["bachelors"],
    "projects_count": 3
  },
  "parsed_jd": { "..." },
  "career_score": {
    "career_score": 76.81,
    "tier": "Strong Match",
    "skill_score": 100.0,
    "semantic_score": 33.23,
    "experience_score": 90.0,
    "education_score": 70.0
  },
  "skill_profile": {
    "matched_skills": ["dart", "firebase", "flutter", "git"],
    "missing_skills": [],
    "skill_strengths": ["supabase"],
    "skill_coverage_%": 100.0,
    "suggested_roles": [
      {"role": "Mobile App Developer (Flutter)", "match_percent": 83.3}
    ],
    "learning_resources": [],
    "recommendations": ["Excellent skill coverage! Highlight your matched skills..."]
  }
}
```

---

## 🧠 AI Pipeline

```
Profile Text + JD Text
        │
        ▼
┌─────────────────┐
│  NLPParser      │  → Regex-based skill extraction, experience parsing, education detection
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SemanticMatcher│  → TF-IDF Vectorization + Cosine Similarity, Skill Overlap Sets
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CareerScorer   │  → Weighted score: Skill(40%) + Semantic(25%) + Exp(20%) + Edu(15%)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SkillProfiler  │  → Role fingerprinting, gap analysis, resources, recommendations
└─────────────────┘
         │
         ▼
   Final Result Dict
```

---

## 📋 Scoring Weights

| Component | Weight | Description |
|---|---|---|
| Skill Match | **40%** | % of required JD skills possessed |
| Semantic Similarity | **25%** | TF-IDF cosine similarity of full texts |
| Experience | **20%** | Years compared to JD requirement |
| Education | **15%** | Highest degree level |

---

## ✅ Test Results

| Test Case | Career Score | Tier |
|---|---|---|
| Flutter Dev vs Flutter JD | **76.81 / 100** | Strong Match |
| Data Scientist vs ML Engineer JD | **76.66 / 100** | Strong Match |
| Fresh Grad vs Frontend JD | **54.05 / 100** | Weak Match (no exp) |
| Mismatch: Mobile Dev vs ML JD | **29.48 / 100** | Poor Match |

---

## 🔗 Future API Integration

To connect this module to the AlumniConnect backend, wrap the engine in a REST endpoint:

```python
# Example FastAPI integration (future)
from fastapi import FastAPI
from career_twin.engine import CareerTwinEngine

app = FastAPI()

@app.post("/api/career-match")
def match(profile_text: str, jd_text: str, required_experience: float = 0.0):
    return CareerTwinEngine.analyze(profile_text, jd_text, required_experience)
```

---

> **Note**: No external LLM API keys required. Fully offline using scikit-learn TF-IDF embeddings.
