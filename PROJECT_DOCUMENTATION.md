# 📚 AlumniConnect AI — Complete Project Documentation
### Smart India Hackathon | Full Flow, Tools, Libraries & Architecture

---

## 📌 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Complete Flow — Start to End](#2-complete-flow--start-to-end)
3. [Project Folder Structure](#3-project-folder-structure)
4. [AI Modules — What They Do](#4-ai-modules--what-they-do)
5. [Python Backend — Libraries & Why](#5-python-backend--libraries--why)
6. [PDF Extraction — 4-Strategy Pipeline](#6-pdf-extraction--4-strategy-pipeline)
7. [Flutter Frontend — Libraries & Why](#7-flutter-frontend--libraries--why)
8. [Firebase & Supabase — Why Both](#8-firebase--supabase--why-both)
9. [State Management — Provider Pattern](#9-state-management--provider-pattern)
10. [Offline Fallback System](#10-offline-fallback-system)
11. [Deployment — Render + GitHub Actions](#11-deployment--render--github-actions)
12. [Bugs Fixed in This Session](#12-bugs-fixed-in-this-session)
13. [Files Created or Modified](#13-files-created-or-modified)
14. [Tech Stack Summary Table](#14-tech-stack-summary-table)

---

## 1. Project Overview

**AlumniConnect** is an AI-powered alumni networking platform built for the **Smart India Hackathon**.

The app connects **students** with **alumni mentors** using 4 real AI/ML models:

| AI Engine | What It Does |
|-----------|-------------|
| 🤖 AI Career Twin | Matches your resume against a job description and gives an ATS score |
| 🗺️ AI Career GPS | Gives you a step-by-step career roadmap based on your skills |
| 📊 AI Skill Gap Analyzer | Finds which skills you are missing for your target domain |
| 🤝 AI Mentor Match | Finds alumni mentors who match your skills using SBERT AI |

---

## 2. Complete Flow — Start to End

### Step-by-Step User Journey

```
USER OPENS APP
      │
      ▼
┌─────────────────────┐
│  Login / Register   │  ← Firebase Auth (email/Google)
│  (Student / Alumni) │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│    Home Screen      │  ← Shows feed, events, jobs, alumni list
│  (Dashboard)        │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│    AI Hub Screen    │  ← Entry point for all 4 AI engines
│  (4 Engine Cards)   │
└────────┬────────────┘
         │
    ┌────┴───────────────────────────────────────┐
    │                                            │
    ▼                                            ▼
[ Card 1 ]                                  [ Card 4 ]
AI Career Twin                           AI Mentor Match
    │                                            │
    ▼                                            ▼
Upload Resume PDF                        (Uses same uploaded PDF)
    │
    ▼
┌─────────────────────────────────────────────────┐
│  RESUME UPLOAD PIPELINE                         │
│                                                 │
│  1. FilePicker → select PDF from phone          │
│  2. Send PDF bytes → Python Server              │
│     POST /resume/upload                         │
│  3. Python uses PyMuPDF → extract text          │
│  4. CandidateProfileBuilder → parse JSON        │
│  5. Return CandidateProfile (structured JSON)   │
│                                                 │
│  (If Python server is offline →                 │
│   Dart native PDF parser runs instead)          │
└──────────────────┬──────────────────────────────┘
                   │
         CandidateProfile JSON stored in
         AISessionCache (shared across all screens)
                   │
    ┌──────────────┼───────────────────┐
    │              │                   │
    ▼              ▼                   ▼
Career Twin    Career GPS         Skill Gap +
 Analyze        Analyze          Mentor Match
    │              │                   │
    ▼              ▼                   ▼
POST             POST              POST
/career-twin/  /career-gps/   /alumni-skill/analyze
analyze         analyze        + /mentor-match/analyze
    │              │                   │
    ▼              ▼                   ▼
Match Score    Roadmap Steps    Missing Skills +
ATS Score      Certifications   Ranked Mentors
Matched Skills Suggested Jobs   Why AI matched
    │              │                   │
    ▼              ▼                   ▼
          SHOW RESULTS ON SCREEN
```

---

### Resume Upload — Detailed Flow

```
User picks PDF
      │
      ▼
Flutter: FilePicker.platform.pickFiles(type: FileType.custom, ext: ['pdf'])
      │
      Returns: Uint8List (raw PDF bytes)
      │
      ▼
AIService.uploadResumeBytes(pdfBytes, filename)
      │
      ├── Try: POST http://10.0.2.2:8000/resume/upload  ← Python server
      │         timeout: 10 seconds
      │         │
      │         If SUCCESS (200 OK):
      │         ├── PyMuPDF extracts text from PDF
      │         ├── CandidateProfileBuilder parses:
      │         │     - Name, Email, Phone
      │         │     - Skills (languages, frameworks, tools)
      │         │     - Education (degree, institution, year)
      │         │     - Work Experience (roles, companies, dates)
      │         │     - Projects
      │         │     - Total Experience (years/months)
      │         │     - Domain detection (Data Analytics, Mobile Dev, etc.)
      │         └── Returns CandidateProfile JSON
      │
      └── If TIMEOUT / SERVER OFFLINE:
              Dart native fallback (_parsePdfBytesLocally)
              ├── Read raw PDF bytes
              ├── Extract text from parenthesis streams
              ├── Detect skills using regex keyword matching
              ├── Auto-detect domain
              └── Return same CandidateProfile JSON shape
```

---

### Mentor Match — Detailed Flow

```
CandidateProfile ready
      │
      ▼
AlumniSkillService.analyzeAndMatchAlumni()
      │
      ├── Step 1: Python /alumni-skill/analyze
      │   ├── Sends: candidate skills + target role
      │   ├── Returns: missing_critical_skills, missing_secondary_skills
      │   └── timeout: 10s → continues without if offline
      │
      ├── Step 2: MentorMatchService.findMentors()
      │   │
      │   ├── Firestore query: users where role == 'alumni'
      │   │   timeout: 5 seconds
      │   │   │
      │   │   If Firestore has alumni:
      │   │   └── Use real alumni data
      │   │
      │   │   If Firestore empty / timeout:
      │   │   └── Use 5 Dummy Mentors (Demo Data placeholder)
      │   │
      │   ├── POST /mentor-match/analyze
      │   │   ├── SBERT sentence embeddings
      │   │   ├── Cosine similarity: candidate ↔ each alumni
      │   │   ├── Ranks alumni by semantic similarity score
      │   │   └── Returns ranked list with AI explanations
      │   │
      │   └── If SBERT server offline:
      │       └── Jaccard overlap fallback (shared skill counting)
      │
      └── Step 3: Build result cards
          ├── Ranked Alumni Matches (Top 5)
          ├── Mentorship Recommendations
          ├── Networking Suggestions
          └── Career Similarity Insights
```

---

## 3. Project Folder Structure

```
Alumniconnect-master/
│
├── 📁 ai-module/                        ← Python FastAPI Backend
│   ├── api/
│   │   └── main.py                      ← FastAPI app entry point
│   ├── pdf_parser/
│   │   ├── resume_parser.py             ← 4-strategy PDF extractor
│   │   └── candidate_profile_builder.py ← Parses text → structured JSON
│   ├── career_twin/
│   │   ├── career_match_model.py        ← Career Twin AI model
│   │   ├── similarity_engine.py         ← TF-IDF + cosine similarity
│   │   └── ats_score.py                 ← ATS compatibility scorer
│   ├── career_gps/
│   │   └── career_gps_model.py          ← Career GPS roadmap generator
│   └── requirements.txt                 ← Python dependencies
│
├── 📁 Career GPS ai-module/             ← Career GPS AI module (separate)
│
├── 📁 alumini_skill/                    ← Skill Gap Analyzer module
│   └── alumini_skill/
│       ├── skill_gap_analyzer/
│       │   ├── analyzer.py              ← SkillGapAnalyzer class
│       │   └── models.py                ← SkillGapRequest Pydantic model
│       └── examples/
│           └── integration_example.js   ← JS usage example
│
├── 📁 ai-module mentor match/           ← SBERT Mentor Match module
│   └── mentor_match_engine/
│       ├── engine.py                    ← MentorMatchEngine (SBERT)
│       └── models.py                    ← StudentProfile, MentorProfile
│
├── 📁 lib/                              ← Flutter Dart source code
│   ├── config/
│   │   ├── theme.dart                   ← App colors, glassmorphism theme
│   │   └── api_config.dart              ← Centralized API URL config [NEW]
│   ├── screens/
│   │   ├── ai/
│   │   │   ├── ai_hub_screen.dart       ← 4 AI engine cards [UPGRADED]
│   │   │   ├── career_twin_screen.dart  ← Career Twin UI
│   │   │   ├── career_gps_screen.dart   ← Career GPS UI
│   │   │   └── alumni_skill_screen.dart ← Skill Gap + Mentor Match UI
│   │   ├── home/
│   │   ├── chat/
│   │   ├── events/
│   │   ├── jobs/
│   │   ├── profile/
│   │   └── alumni/
│   ├── services/
│   │   ├── ai_service.dart              ← PDF upload + Career Twin [FIXED]
│   │   ├── career_gps_service.dart      ← Career GPS HTTP [FIXED]
│   │   ├── alumni_skill_service.dart    ← Skill gap HTTP [FIXED]
│   │   └── mentor_match_service.dart    ← SBERT + Firestore [FIXED]
│   ├── providers/
│   │   ├── ai_provider.dart             ← Career Twin state
│   │   ├── alumni_skill_provider.dart   ← Skill + Mentor state [FIXED]
│   │   └── ai_session_cache.dart        ← Shared resume cache
│   └── widgets/
│       └── theme/                       ← GlassCard, NeonButton, etc.
│
├── render.yaml                          ← Render deployment config [NEW]
├── CONTRIBUTING.md                      ← Team guide [NEW]
├── PROJECT_DOCUMENTATION.md            ← This file [NEW]
└── .github/
    └── workflows/
        └── ci.yml                       ← GitHub Actions CI/CD [NEW]
```

---

## 4. AI Modules — What They Do

### Module 1: AI Career Twin (`ai-module/career_twin/`)

**Purpose:** Compare a student's resume against a job description and score the match.

**How it works:**
1. Extract candidate skills from CandidateProfile JSON
2. Extract required skills from job description text using keyword matching
3. Calculate **Semantic Similarity** (TF-IDF cosine similarity)
4. Calculate **Skill Overlap** (matched vs. missing skills)
5. Calculate **Experience Match** (candidate years vs. required years)
6. Compute **ATS Score** (Applicant Tracking System compatibility)
7. Generate composite **Match Score** (0–100)

**Output:**
- Match Score (e.g., 82.5)
- Match Tier (Strong / Moderate / Weak)
- Matched Skills list
- Missing Skills list
- ATS Score breakdown
- Recommendations

---

### Module 2: AI Career GPS (`Career GPS ai-module/`)

**Purpose:** Generate a personalized career roadmap with phases, certifications, and projects.

**How it works:**
1. Takes current skills + target role
2. Identifies skill gaps
3. Generates phased learning plan (Phase 1, 2, 3)
4. Recommends specific certifications, courses, projects

**Output:**
- Career phases with milestones
- Certifications to pursue
- Projects to build
- Estimated timeline

---

### Module 3: AI Skill Gap Analyzer (`alumini_skill/`)

**Purpose:** Domain-aware missing skill detection benchmarked against real job roles.

**How it works:**
1. Takes student skills + target domain (e.g., `data_scientist`)
2. Compares against benchmark skill requirements for that role
3. Classifies skills as: ✅ Present | 🔴 Critical Missing | 🟡 Secondary Missing
4. Generates placement readiness score

**Domain → Role ID mapping:**
```
Data Analytics & BI     → data_scientist
AI / Machine Learning   → ai_ml_engineer
Mobile App Development  → mobile_developer
Software Development    → backend_engineer
Cloud Engineering       → cloud_devops_engineer
```

**Output:**
- Missing critical skills
- Missing secondary skills
- Placement readiness score (0–100)
- Readiness level (Beginner / Intermediate / Advanced)

---

### Module 4: AI Mentor Match (`ai-module mentor match/`)

**Purpose:** Find the best alumni mentor for a student using SBERT semantic similarity.

**Technology:** `sentence-transformers` (SBERT — Sentence-BERT)

**How it works:**
1. Encode student profile as a sentence embedding vector
2. Encode each alumni profile as a sentence embedding vector
3. Compute **cosine similarity** between student ↔ each alumni
4. Rank alumni by similarity score (0.0 to 1.0)
5. Generate AI explanation: "Matched because of shared Python, SQL expertise"

**Why SBERT?**
- Regular keyword matching misses semantic meaning (e.g., "Power BI" ≈ "data visualization")
- SBERT understands meaning, not just exact words
- Pre-trained on 1B+ sentence pairs — no retraining needed

**Output:**
- Ranked mentor list with similarity scores
- Match percentage
- Shared skills
- AI-generated explanation
- Why this mentor was selected

---

## 5. Python Backend — Libraries & Why

### FastAPI (`fastapi>=0.100.0`)
**What:** Modern Python web framework for building APIs  
**Why:** Fastest Python API framework. Auto-generates Swagger docs at `/docs`. Async support for handling multiple requests. Pydantic validation built-in.  
**Used for:** All AI endpoints (`/resume/upload`, `/career-twin/analyze`, etc.)

---

### Uvicorn (`uvicorn>=0.20.0`)
**What:** ASGI server that runs the FastAPI app  
**Why:** Production-grade async server. Works with `$PORT` on Render.  
**Start command:** `uvicorn api.main:app --host 0.0.0.0 --port $PORT`

---

### PyMuPDF (`pymupdf>=1.20.0`, imported as `fitz`)
**What:** High-performance PDF parsing library  
**Why:** Best quality text extraction. Handles Canva PDFs, LinkedIn PDFs, ATS-formatted resumes. Preserves whitespace and layout.  
**Used as:** Strategy 1 (primary) in `resume_parser.py`  
```python
import fitz
doc = fitz.open(stream=pdf_bytes, filetype="pdf")
text = page.get_text("text", flags=fitz.TEXT_PRESERVE_WHITESPACE)
```

---

### pdfplumber (`pdfplumber>=0.9.0`)
**What:** PDF text + table extractor  
**Why:** Excellent for PDFs with complex column layouts or tables. Handles positioning-based PDFs.  
**Used as:** Strategy 2 (fallback) in `resume_parser.py`  
```python
import pdfplumber
with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
    text = page.extract_text(x_tolerance=3, y_tolerance=3)
```

---

### pypdf / PyPDF2 (`pypdf>=3.0.0`)
**What:** Pure-Python PDF reader  
**Why:** Lightweight, no C dependencies. Works when fitz/pdfplumber fail.  
**Used as:** Strategy 3 (second fallback) in `resume_parser.py`

---

### scikit-learn (`scikit-learn>=1.0.0`)
**What:** Machine Learning library  
**Why:** Provides TF-IDF vectorizer and cosine similarity for Career Twin matching.  
**Used in:** `similarity_engine.py` for semantic similarity calculation  
```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
```

---

### sentence-transformers (`sentence-transformers>=2.2.0`)
**What:** SBERT — pre-trained sentence embedding model  
**Why:** Converts text into semantic vectors. Understands meaning, not just keywords. Used for mentor matching where "data analyst" ≈ "Power BI developer".  
**Used in:** `mentor_match_engine/engine.py`  
```python
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')
embeddings = model.encode([student_text, alumni_text])
```

---

### PyTorch (`torch>=1.9.0`)
**What:** Deep learning framework  
**Why:** Required by `sentence-transformers` to run the SBERT model. Provides tensor operations for cosine similarity computation.

---

### NumPy (`numpy>=1.21.0`)
**What:** Numerical computing library  
**Why:** Matrix operations for similarity score calculations. Used with scikit-learn and sentence-transformers.

---

### pandas (`pandas>=1.3.0`)
**What:** Data analysis library  
**Why:** Data manipulation in skill gap analyzer. Handles alumni profile data as DataFrames.

---

### scipy (`scipy>=1.7.0`)
**What:** Scientific computing library  
**Why:** Statistical functions used in skill scoring and placement readiness calculation.

---

### python-multipart (`python-multipart>=0.0.6`)
**What:** Multipart form data parser  
**Why:** **Required by FastAPI to accept file uploads.** Without this, `/resume/upload` would reject PDF file uploads.

---

### requests (`requests>=2.28.0`)
**What:** HTTP client for Python  
**Why:** Used in integration tests and utility scripts.

---

## 6. PDF Extraction — 4-Strategy Pipeline

```
PDF bytes
   │
   ▼
Strategy 1: PyMuPDF (fitz)
   - Best quality, handles 95% of resumes
   - Preserves whitespace and layout
   ↓ (if text < 30 chars)
Strategy 2: pdfplumber
   - Better for multi-column, table-heavy layouts
   - Position-aware extraction
   ↓ (if text < 30 chars)
Strategy 3: pypdf / PyPDF2
   - Simple PDFs, no native libraries needed
   - Also tries PyPDF2 if pypdf fails
   ↓ (if text < 30 chars)
Strategy 4: Pure Python zlib decoder
   - Decompresses FlateDecode PDF streams
   - Parses BT...ET operator blocks manually
   - Zero external dependencies
   ↓ (if still no text)
Dart-side fallback (Flutter)
   - Reads raw PDF byte stream
   - Extracts text from (parenthesis content) blocks
   - Detects skills via regex keyword matching
```

---

## 7. Flutter Frontend — Libraries & Why

### `flutter` (SDK)
The core framework. Builds cross-platform mobile apps (Android + iOS) from a single codebase in Dart.

---

### `provider: ^6.1.2`
**What:** State management library  
**Why:** Manages AI analysis state across screens. When a resume is uploaded on one screen, the parsed profile is available on all other screens.  
**Pattern used:** `ChangeNotifier` + `Consumer<Provider>`  
**Providers in this project:**
- `AIProvider` — Career Twin state
- `AlumniSkillProvider` — Skill Gap + Mentor Match state

---

### `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
**What:** Firebase SDK packages  
**Why:**
- `firebase_auth` → Login/Register with email + Google
- `cloud_firestore` → Alumni profiles, events, jobs stored here
- `firebase_messaging` → Push notifications for new job posts, events

---

### `http: ^1.6.0`
**What:** HTTP client for Dart  
**Why:** Makes POST requests to the Python FastAPI backend (`/resume/upload`, `/career-twin/analyze`, etc.). All AI calls go through this.

---

### `file_picker: ^8.0.0`
**What:** Cross-platform file picker  
**Why:** Lets the user pick a PDF from their phone storage. Returns `Uint8List` (raw bytes) which we send to the Python server.  
```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
  withData: true,
);
```

---

### `supabase_flutter: ^2.5.6`
**What:** Supabase SDK for Flutter  
**Why:** Used for file storage (profile photos, resume uploads). Supabase provides S3-compatible object storage which Firebase doesn't offer on free tier.

---

### `image_picker: ^1.0.7` + `image_cropper: ^8.1.0`
**What:** Photo picker and cropper  
**Why:** Profile photo upload. User picks photo from gallery/camera, crops it, then uploads to Supabase Storage.

---

### `shimmer: ^3.0.0`
**What:** Loading skeleton animation  
**Why:** Shows animated placeholder cards while AI results are loading. Better UX than a spinner.

---

### `table_calendar: ^3.0.9`
**What:** Calendar widget  
**Why:** Events screen — shows alumni events in calendar view with date selection.

---

### `url_launcher: ^6.2.5`
**What:** Opens URLs in browser  
**Why:** Opens LinkedIn profiles, certification links, job application URLs.

---

### `shared_preferences: ^2.2.2`
**What:** Key-value local storage  
**Why:** Saves user preferences (theme, notification settings) locally on device.

---

### `flutter_dotenv: ^5.1.0`
**What:** `.env` file loader  
**Why:** Loads Firebase keys, Supabase URL from `.env` file. Keeps secrets out of code.

---

### `appwrite: ^21.0.0`
**What:** Appwrite backend SDK  
**Why:** Additional backend service for some real-time features.

---

## 8. Firebase & Supabase — Why Both?

| Feature | Firebase | Supabase |
|---------|----------|----------|
| Authentication | ✅ Used (email, Google) | ❌ Not used |
| Database | ✅ Firestore (alumni data, events, jobs) | ❌ Not used |
| Push Notifications | ✅ Firebase Messaging | ❌ Not used |
| File Storage | ❌ Expensive on free tier | ✅ Used (profile photos, resumes) |
| Reason for both | Best-in-class auth + realtime DB | Free 1GB object storage |

---

## 9. State Management — Provider Pattern

```
AlumniSkillProvider (ChangeNotifier)
│
├── isLoading: bool        → shows spinner in UI
├── error: String?         → shows error message
├── parsedProfile: Map?    → CandidateProfile JSON
├── result: Map?           → analysis results
│
├── analyzeResumeBytes()   → called when user uploads PDF
│   ├── sets isLoading = true  → notifyListeners()
│   ├── calls AIService.uploadResumeBytes()
│   ├── calls AlumniSkillService.analyzeAndMatchAlumni()
│   └── sets isLoading = false → notifyListeners()
│
└── Consumer<AlumniSkillProvider> in UI
    ├── if isLoading → show shimmer/spinner
    ├── if error != null → show error snackbar
    └── if result != null → show AI result cards
```

**AISessionCache** — Singleton shared across all providers:
```
Upload PDF once → profile cached in AISessionCache
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
  CareerTwin          CareerGPS         AlumniSkill
  (reuses cache)     (reuses cache)    (reuses cache)
```
No repeated PDF parsing — parse once, use everywhere.

---

## 10. Offline Fallback System

The app **never freezes** regardless of network state:

| Scenario | Timeout | Fallback |
|----------|---------|---------|
| Python server offline | 10s | Dart native PDF parser |
| Career Twin server error | 10s | Dart TF-IDF native engine |
| Skill Gap server error | 10s | Continue without skill gap |
| **Firestore slow/offline** | **5s** | **5 Dummy Mentor profiles** |
| SBERT server offline | 10s | Jaccard overlap ranking |

### 5 Dummy Mentor Profiles (Demo Data)

These appear when Firestore has no alumni data (useful for demos):

| # | Name | Role | Company | Skills |
|---|------|------|---------|--------|
| 1 | Priya S. (Demo Data) | Senior Data Analyst | Zoho | Python, SQL, Power BI |
| 2 | Arun K. (Demo Data) | Flutter Developer | Freshworks | Flutter, Firebase, Dart |
| 3 | Kavya M. (Demo Data) | AI Engineer | TCS | Python, TensorFlow, NLP |
| 4 | Sanjay R. (Demo Data) | Cloud Engineer | Infosys | Azure, Docker, Kubernetes |
| 5 | Divya P. (Demo Data) | BI Developer | Cognizant | SQL, Tableau, Power BI |

All have `'is_demo': true` — easy to identify and replace with real Firestore data later.

---

## 11. Deployment — Render + GitHub Actions

### Render (Python Backend)

File: `render.yaml`

```
GitHub repo → Render Web Service
              rootDir: ai-module
              buildCommand: pip install -r requirements.txt
              startCommand: uvicorn api.main:app --host 0.0.0.0 --port $PORT
              healthCheckPath: /health
              autoDeploy: true (on push to main)
```

**Production URL:** `https://alumniconnect-ai.onrender.com`

### Flutter API Switch

Change one line in `lib/config/api_config.dart`:
```dart
// For local testing (Android emulator):
static const ApiEnvironment environment = ApiEnvironment.local;

// For production (Render):
static const ApiEnvironment environment = ApiEnvironment.production;
```

### GitHub Actions CI/CD

File: `.github/workflows/ci.yml`

**On Pull Request:**
- `flutter pub get`
- `flutter analyze --no-fatal-infos`
- `flutter test`
- `pip install -r ai-module/requirements.txt`
- `flake8` Python lint check
- FastAPI import test

**On merge to `main`:**
- Auto-triggers Render deployment via deploy hook

---

## 12. Bugs Fixed in This Session

### Bug 1 — Python `ModuleNotFoundError`
**File:** `ai-module/api/main.py`  
**Problem:** `career_twin.career_match_model` module not found when server started  
**Root cause:** `os.path.dirname(os.path.dirname(__file__))` resolved wrong directory  
**Fix:** Used `os.path.abspath()` from `__file__` anchor point  

### Bug 2 — Flutter Build Error (`argument_type_not_assignable`)
**File:** `lib/providers/alumni_skill_provider.dart:234`  
**Problem:** `profile` typed as `Map<String, dynamic>?` (nullable) passed to non-nullable param  
**Fix:** `candidateProfile: profile!` (safe — guarded by null check above)  

### Bug 3 — Raw HTML shown in UI on 404 error
**File:** `lib/services/ai_service.dart`  
**Problem:** When server returned 404, `<!doctype html>` shown as error text  
**Fix:** Added `_extractDetail()` to sanitize HTML responses  

### Bug 4 — App freezes 2+ minutes after PDF upload
**File:** `lib/services/mentor_match_service.dart`  
**Root cause:** Firestore `.get()` had no timeout — hangs indefinitely on slow networks  
**Fix:** Added `.timeout(const Duration(seconds: 5))` to all 3 Firestore queries  

### Bug 5 — 17-Year experience calculation bug
**File:** `ai-module/pdf_parser/candidate_profile_builder.py`  
**Problem:** College year ranges (e.g., 2007–2024 = 17) counted as work experience  
**Fix:** Clamped experience to max 10 years, excluded education section date ranges  

### Bug 6 — Gradle build `!zip.isFile()` error
**Type:** Build tooling (not code)  
**Root cause:** Corrupted ZIP artifact in `~/.gradle/caches` from interrupted download  
**Fix:** `gradlew --stop` → `flutter clean` → delete `~/.gradle/caches` → `flutter pub get` → rebuild  

---

## 13. Files Created or Modified

| File | Status | Description |
|------|--------|-------------|
| `lib/config/api_config.dart` | 🆕 NEW | Centralized API URL — switch local/production with one line |
| `lib/services/ai_service.dart` | ✏️ MODIFIED | Native PDF fallback, Career Twin fallback, HTML sanitization |
| `lib/services/career_gps_service.dart` | ✏️ MODIFIED | Uses `ApiConfig.baseUrl` instead of hardcoded IP |
| `lib/services/alumni_skill_service.dart` | ✏️ MODIFIED | Uses `ApiConfig`, timeout constants, unused var removal |
| `lib/services/mentor_match_service.dart` | ✏️ MODIFIED | 5s Firestore timeout, 5 dummy mentors, smart fallback pipeline |
| `lib/providers/alumni_skill_provider.dart` | ✏️ MODIFIED | Fixed null-safety `profile!` assertion |
| `lib/screens/ai/ai_hub_screen.dart` | ✏️ MODIFIED | 4 premium AI cards (was 3) |
| `ai-module/api/main.py` | ✏️ MODIFIED | Fixed `sys.path` for module resolution |
| `render.yaml` | 🆕 NEW | Render Web Service deployment configuration |
| `.github/workflows/ci.yml` | 🆕 NEW | GitHub Actions CI/CD pipeline |
| `CONTRIBUTING.md` | 🆕 NEW | Team collaboration guide |
| `PROJECT_DOCUMENTATION.md` | 🆕 NEW | This document |

---

## 14. Tech Stack Summary Table

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Mobile Framework** | Flutter | SDK ^3.10 | Cross-platform Android + iOS app |
| **Language (App)** | Dart | 3.x | Flutter app code |
| **Language (AI)** | Python | 3.11 | AI backend |
| **AI Backend Framework** | FastAPI | >=0.100 | REST API server |
| **AI Server Runner** | Uvicorn | >=0.20 | ASGI production server |
| **PDF Extraction #1** | PyMuPDF (fitz) | >=1.20 | Primary PDF text extractor |
| **PDF Extraction #2** | pdfplumber | >=0.9 | Multi-column PDF fallback |
| **PDF Extraction #3** | pypdf / PyPDF2 | >=3.0 | Simple PDF second fallback |
| **PDF Extraction #4** | Pure Python zlib | built-in | Zero-dep last resort |
| **PDF Extraction #5** | Dart byte parser | custom | Offline Flutter fallback |
| **Mentor Matching AI** | SBERT (sentence-transformers) | >=2.2 | Semantic mentor matching |
| **Deep Learning** | PyTorch | >=1.9 | Powers SBERT embeddings |
| **ML Library** | scikit-learn | >=1.0 | TF-IDF, cosine similarity |
| **Numerical** | NumPy | >=1.21 | Matrix operations |
| **Data** | pandas | >=1.3 | Data manipulation |
| **Auth** | Firebase Auth | ^6.1.4 | Email + Google login |
| **Database** | Cloud Firestore | ^6.1.2 | Alumni, events, jobs data |
| **Storage** | Supabase | ^2.5.6 | File/photo storage |
| **Notifications** | Firebase Messaging | ^16.1.1 | Push notifications |
| **State Management** | Provider | ^6.1.2 | App-wide state |
| **HTTP Client (Dart)** | http | ^1.6.0 | API calls to Python |
| **File Picker** | file_picker | ^8.0.0 | PDF selection |
| **Deployment** | Render | — | Python backend hosting |
| **CI/CD** | GitHub Actions | — | Auto test + deploy |
| **Version Control** | Git + GitHub | — | Code collaboration |

---

## 🚀 How to Run the Project

### Start Python AI Server (Windows)
```batch
# Option 1: Use the batch file
start_ai_server.bat

# Option 2: Manual
cd ai-module
pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

### Start Flutter App
```powershell
cd Alumniconnect-master

# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build APK
flutter build apk --debug
```

### Test AI Backend
```powershell
# Health check
curl http://localhost:8000/health

# View all endpoints
# Open browser: http://localhost:8000/docs
```

---

*AlumniConnect AI — Smart India Hackathon 2024*  
*Documentation generated: September 2026*
