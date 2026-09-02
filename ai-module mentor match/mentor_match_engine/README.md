# 🧠 Mentor Match Engine — SBERT Cosine Similarity & Ranking Engine

> **Version:** 0.3.0 (Step 4 Complete)  
> **Status:** Full Semantic Cosine Similarity & Top-K Ranking Engine Implemented & Verified  
> **Module Path:** `ai-module/mentor_match_engine/`

---

## Overview

The **Mentor Match Engine** recommends the best alumni mentors for a student based on multi-dimensional semantic profile similarity using **Sentence-BERT (SBERT)** embeddings and **Cosine Similarity**.

In **Step 4**, we implemented:
1. **`similarity_engine.py`**: Pure linear algebra matrix Cosine Similarity engine.
2. **`mentor_ranker.py`**: Top-K sorting, case-insensitive skill overlap analysis, and human-readable match reason generation.
3. **`engine.py`**: Top-level `MentorMatchEngine.match_student()` orchestrator chaining Encoder → Similarity → Ranker.

---

## 📐 Cosine Similarity & Score Normalization

### What is Cosine Similarity?
Cosine Similarity measures the cosine of the angle between two dense vectors in SBERT's 384-dimensional embedding space:

$$\text{Cosine Similarity}(v_A, v_B) = \frac{v_A \cdot v_B}{\|v_A\| \|v_B\|}$$

When SBERT embeddings are L2-normalized ($\|v\| = 1.0$), cosine similarity reduces to a fast dot product:

$$\text{Cosine Similarity}(v_A, v_B) = v_A \cdot v_B$$

### Why Use Cosine Similarity for Mentor Matching?
Unlike Euclidean distance (which measures absolute metric distance), **Cosine Similarity evaluates orientation and semantic direction**. A student interested in "AI / Machine Learning" and a mentor working as a "Senior Deep Learning Researcher" will point in nearly the same direction in vector space, yielding a high similarity score even if their text length differs.

### Raw Cosine Score vs User-Facing Match Percentage

| Metric | Range | Description |
|--------|-------|-------------|
| **Raw Cosine Similarity** | `[-1.0, 1.0]` | Unmodified mathematical similarity score (e.g. `0.8421`) |
| **Match Percentage** | `[0.0%, 100.0%]` | User-friendly presentation score (`round(raw_score * 100, 1)`) |

---

## 🏗 Complete End-to-End Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│ Student Profile                                             │
│ (Name, Department, Skills, Interests, Career Goals, Bio)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Profile Encoder (SBERT)                                     │
│ Model: sentence-transformers/all-MiniLM-L6-v2             │
│ Generates L2-normalized 384-dimensional vector              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Similarity Engine (NumPy)                                   │
│ Computes batch Cosine Similarity matrix against candidate   │
│ mentor profile vector embeddings                            │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Mentor Ranker                                               │
│ • Sorts mentors descending by similarity score              │
│ • Filters top_k matches (default top_k=5)                   │
│ • Computes technical skill overlap                          │
│ • Generates human-readable match explanations               │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Top-K Mentor Recommendations                                │
│ List[MentorMatchResult] containing ranked mentor objects,   │
│ similarity scores, match percentages, and explanations      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Running the End-to-End Matching Demo

The demo script evaluates two contrasting student profiles (**Student A: AI/ML** vs **Student B: Full Stack Web**) against 10 alumni mentors:

```bash
py mentor_match_engine/demo_matching.py
```

### Key Demonstration Outcomes
- **Student A (AI Specialist):** Receives **Dr. Aris Vance** (AI/ML Research Scientist, 74.2% match) as Top #1 match.
- **Student B (Full Stack Web):** Receives **Siddharth Rao** (Full Stack Architect, 77.8% match) as Top #1 match.
- **Semantic Differentiation:** Proves recommendations dynamically adapt to career goals and skills without hardcoding.

---

## 🧪 Running the Test Suite

Run all Step 4 unit and integration tests:

```bash
py mentor_match_engine/tests/test_mentor_match_engine.py
```

---

## 📂 Module Folder Structure

```text
mentor_match_engine/
├── __init__.py                 ← Package init (MentorMatchEngine)
├── engine.py                   ← Main orchestrator (match_student)
├── models.py                   ← StudentProfile, MentorProfile, MentorMatchResult
├── profile_encoder.py          ← SBERT ProfileEncoder (384-dim vectors)
├── similarity_engine.py        ← Cosine Similarity engine (IMPLEMENTED IN STEP 4)
├── mentor_ranker.py            ← Top-K Ranker & Match Explanations (IMPLEMENTED IN STEP 4)
├── demo_encoder.py             ← SBERT encoder demo
├── demo_matching.py            ← End-to-end matching demo (NEW IN STEP 4)
├── README.md                   ← Module documentation (this file)
├── data/
│   └── sample_mentors.json     ← 10 sample alumni profiles
└── tests/
    ├── __init__.py
    └── test_mentor_match_engine.py  ← Comprehensive Step 4 test suite
```

---

## 🛡 Safety & Decoupling

- ❌ **Career Twin AI** (`ai-module/career_twin/`) remains **100% untouched**.
- ❌ **Flutter Mobile App** (`Alumniconnect-master/`) remains **100% untouched**.
- ❌ **No API endpoints or Flutter UI integrations created yet.**
