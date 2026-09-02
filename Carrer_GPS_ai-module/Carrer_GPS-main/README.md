# Career GPS Engine

An AI-powered, structured career planning and recommendations engine. It processes a user's career profile (including education, current skills, projects, work experience, certifications, and interests) to generate a career readiness score, perform a deterministic skill gap analysis, sequence learning phases based on dependency trees, recommend targeted projects to close gaps, and output a personalized career transition roadmap.

The system uses a hybrid architecture, combining deterministic business rules (for matching, gaps, readiness, and sequence) with an LLM synthesizer (Gemini) to personalize explanations and suggest the next best action.

---

## 1. Directory Structure

```
career-gps-engine/
├── app/
│   ├── __init__.py
│   ├── api_routes.py
│   ├── core/
│   │   ├── config.py
│   │   └── constants.py
│   ├── models/
│   │   ├── profile.py
│   │   ├── career.py
│   │   ├── skill.py
│   │   ├── roadmap.py
│   │   └── result.py
│   ├── engine/
│   │   ├── career_gps.py
│   │   ├── profile_analyzer.py
│   │   ├── career_matcher.py
│   │   ├── skill_gap_analyzer.py
│   │   ├── readiness_scorer.py
│   │   ├── roadmap_planner.py
│   │   └── recommendation_engine.py
│   ├── ai/
│   │   ├── llm_service.py
│   │   ├── embedding_service.py
│   │   ├── prompts.py
│   │   └── output_parser.py
│   ├── knowledge/
│   │   ├── career_database.py
│   │   ├── skill_database.py
│   │   └── learning_database.py
│   └── utils/
│       ├── normalization.py
│       └── scoring.py
├── data/
│   ├── careers.json
│   ├── skills.json
│   ├── career_skill_matrix.json
│   ├── learning_paths.json
│   └── projects.json
├── tests/
│   ├── test_profile_analyzer.py
│   ├── test_career_matcher.py
│   ├── test_skill_gap.py
│   ├── test_readiness.py
│   └── test_roadmap.py
├── examples/
│   ├── flutter_developer.json
│   ├── flutter_developer_intermediate.json
│   ├── data_scientist.json
│   ├── backend_developer.json
│   └── cs_student_no_exp.json
├── scripts/
│   ├── build_embeddings.py
│   └── evaluate_engine.py
├── requirements.txt
├── .env.example
├── README.md
└── main.py
```

---

## 2. Prerequisites & Setup

The Career GPS Engine requires **Python 3.11+**.

### 2.1. Environment Setup

1. **Install python@3.11** if not already present on your system:
   ```bash
   brew install python@3.11
   ```

2. **Initialize a Virtual Environment**:
   ```bash
   python3.11 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install Dependencies**:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

### 2.2. Configuration

Copy the example environment template and configure your parameters:
```bash
cp .env.example .env
```

Edit the `.env` file to add your Google Gemini API Key:
```env
LLM_PROVIDER=gemini
LLM_API_KEY=AIzaSy...
```
*Note: If no API key is specified, the system automatically falls back to a deterministic `MockLLMService` which returns structured mock JSON, ensuring you can still run the entire system offline.*

---

## 3. Operations

### 3.1. Build & Cache Career Embeddings
Run the offline embeddings script to generate semantic vectors for the 15 standard careers in our database. This speeds up match processing:
```bash
python scripts/build_embeddings.py
```

### 3.2. Start the API Server
Launch the FastAPI server:
```bash
python main.py
```
The API will be available at `http://localhost:8000`. Interactive Swagger docs are at `http://localhost:8000/docs`.

### 3.3. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/careers` | List all available career paths |
| `GET` | `/careers/{id}` | Get details for a specific career |
| `GET` | `/skills` | List all known skills and categories |
| `POST` | `/analyze` | Analyze a career profile and generate roadmap |

### 3.4. Example API Calls

**Health Check:**
```bash
curl http://localhost:8000/health
```

**List Careers:**
```bash
curl http://localhost:8000/careers
```

**Analyze a Career Profile:**
```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d @examples/flutter_developer.json
```

### 3.5. Run Metric Evaluations
Check the performance metrics (Career Match Accuracy, Skill Gap IoU, Roadmap Relevance, Project Relevance, LLM Validity) against expected outcomes for all 5 sample profiles:
```bash
python scripts/evaluate_engine.py
```

### 3.6. Run Tests
To run all tests (engine + API):
```bash
python -m pytest tests/ -v
```
