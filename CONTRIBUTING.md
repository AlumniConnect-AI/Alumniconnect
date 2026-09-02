# Contributing to AlumniConnect AI

Welcome to the AlumniConnect AI project — the Smart India Hackathon AI-powered alumni networking platform!
This guide covers everything you need to collaborate effectively as a team.

---

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Branch Naming Convention](#branch-naming-convention)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Workflow](#pull-request-workflow)
- [Code Review Rules](#code-review-rules)
- [Flutter Commands](#flutter-commands)
- [Python Backend Commands](#python-backend-commands)
- [AI Module Rules](#ai-module-rules)

---

## 🚀 Getting Started

### Clone the Repository

```bash
# Clone from GitHub Organization
git clone https://github.com/AlumniConnect-AI/alumniconnect.git

# Navigate into the project
cd alumniconnect
```

### Flutter Setup

```bash
# Install Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run in release mode
flutter run --release
```

### Python Backend Setup

```bash
# Navigate to AI module
cd ai-module

# Install dependencies
pip install -r requirements.txt

# Start the AI server (Windows)
cd ..
start_ai_server.bat

# Start manually (any OS)
cd ai-module
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🌿 Branch Naming Convention

Always branch from `main`. Use the following naming pattern:

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<short-name>` | `feature/mentor-match-ui` |
| Bug Fix | `fix/<issue-name>` | `fix/experience-calculation-bug` |
| Hotfix | `hotfix/<name>` | `hotfix/server-crash` |
| AI Module | `ai/<model-name>` | `ai/skill-gap-improvements` |
| Release | `release/<version>` | `release/v1.2.0` |
| Docs | `docs/<topic>` | `docs/api-endpoints` |

### Create and switch to a feature branch

```bash
# Always start from updated main
git checkout main
git pull origin main

# Create your feature branch
git checkout -b feature/<feature-name>
```

---

## 💬 Commit Message Convention

Follow the **Conventional Commits** format:

```
<type>(<scope>): <short description>
```

### Types

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `ui` | UI/design changes |
| `ai` | AI model integration change |
| `refactor` | Code refactoring (no new feature) |
| `docs` | Documentation changes |
| `test` | Adding or fixing tests |
| `chore` | Build scripts, config, dependencies |
| `perf` | Performance improvements |

### Examples

```bash
git commit -m "feat(mentor-match): add SBERT semantic matching endpoint"
git commit -m "fix(experience): correct date range parsing for internships"
git commit -m "ui(ai-hub): add 4th AI Mentor Match card with neon gradient"
git commit -m "ai(skill-gap): add aiMlTools category to skills extraction"
git commit -m "chore(render): add render.yaml deployment configuration"
```

---

## 🔄 Pull Request Workflow

### Step-by-Step

```bash
# 1. Make sure you are on your feature branch
git checkout feature/<feature-name>

# 2. Add your changes
git add .

# 3. Commit with a descriptive message
git commit -m "feat(screen): add premium Career Twin score ring"

# 4. Stay up to date with main
git pull origin main
git merge main

# 5. Push your branch
git push origin feature/<feature-name>

# 6. Open a Pull Request on GitHub
# Go to: https://github.com/AlumniConnect-AI/alumniconnect/compare
```

### PR Template

When opening a PR, include:

```markdown
## Summary
Brief description of what this PR does.

## Changes
- [ ] UI/screen changes
- [ ] API/backend changes
- [ ] AI model integration
- [ ] Bug fix

## Testing Done
- Tested on Android emulator
- Tested on physical device
- Verified AI server response

## Screenshots (if UI change)
Add screenshots here.
```

---

## 👁️ Code Review Rules

- **Minimum 1 approval** required before merge.
- Never merge your own PR (unless emergency with team lead consent).
- Review within **24 hours** of PR opening.
- Use GitHub inline comments for specific line feedback.
- Resolve all comments before merging.
- If changes are requested, push new commits (do not force-push).

### Review Checklist

- [ ] Code runs without errors
- [ ] No hardcoded secrets or API keys
- [ ] No hardcoded `localhost` or IP addresses (use `ApiConfig.baseUrl`)
- [ ] Null safety respected
- [ ] No `print()` statements in production code
- [ ] No dummy/placeholder data committed as final (mark with "// TODO: replace with real data")
- [ ] UI tested in both light and dark mode

---

## 🐦 Flutter Commands

```bash
# Get all packages
flutter pub get

# Run the app (debug)
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Check Flutter environment
flutter doctor
```

---

## 🐍 Python Backend Commands

```bash
# Navigate to AI module
cd ai-module

# Install all dependencies (including SBERT for mentor match)
pip install -r requirements.txt
pip install sentence-transformers

# Start development server
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

# Test that the server starts
python -c "from api.main import app; print('OK')"

# Check health endpoint
curl http://localhost:8000/health

# Test resume upload
curl -X POST http://localhost:8000/resume/upload -F "file=@/path/to/resume.pdf"

# List all API routes
python -c "from api.main import app; [print(r.path) for r in app.routes]"
```

---

## 🤖 AI Module Rules

> **CRITICAL: Do NOT modify AI model weights, training data, or model architecture.**

The following AI modules are production-trained and must not be changed:

| Module | Directory | Purpose |
|--------|-----------|---------|
| Career Twin | `ai-module/career_twin/` | Resume vs JD matching |
| Career GPS | `Career GPS ai-module/` | Career roadmap generation |
| Skill Gap Analyzer | `alumini_skill/alumini_skill/` | Placement readiness |
| Mentor Match | `ai-module mentor match/` | SBERT semantic mentor ranking |

**You MAY:**
- Fix API endpoint integration code (`api/main.py`)
- Fix Flutter service code (`lib/services/`)
- Fix UI screens (`lib/screens/ai/`)
- Add new API endpoints to `api/main.py`
- Fix Python path issues in startup scripts

**You MUST NOT:**
- Modify `*.pkl`, `*.h5`, `*.pt`, `*.bin` model files
- Retrain any model
- Change model architectures

---

## 📞 Team Contacts

| Role | Team | GitHub |
|------|------|--------|
| Flutter Lead | Flutter Developers | @rk9528 |
| AI Lead | AI / ML Engineers | - |
| Backend Lead | Backend / API Engineers | - |

---

*AlumniConnect AI — Smart India Hackathon 2024*
