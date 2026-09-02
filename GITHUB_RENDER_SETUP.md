# 🚀 GitHub Organization + Render Deployment — Step-by-Step Guide
### AlumniConnect AI | Smart India Hackathon

> **This guide covers everything you need to do manually on the browser.**
> Every step has exact button names, field values, and what to type.

---

## 📌 Table of Contents

1. [GitHub — Create Organization](#part-1-github--create-organization)
2. [GitHub — Transfer Repository](#part-2-github--transfer-repository)
3. [GitHub — Create Teams & Add Members](#part-3-github--create-teams--add-members)
4. [GitHub — Branch Protection Rules](#part-4-github--branch-protection-rules)
5. [Render — Deploy Python AI Backend](#part-5-render--deploy-python-ai-backend)
6. [Render — Set Environment Variables (Secrets)](#part-6-render--set-environment-variables-secrets)
7. [Connect Render Auto-Deploy to GitHub](#part-7-connect-render-auto-deploy-to-github)
8. [Flutter — Switch to Production URL](#part-8-flutter--switch-to-production-url)
9. [Test Everything is Working](#part-9-test-everything-is-working)

---

## PART 1: GitHub — Create Organization

### Step 1.1 — Open GitHub Organization Creation Page

1. Open your browser
2. Go to: **https://github.com/organizations/plan**
3. Sign in with your GitHub account (`rk9528`)

---

### Step 1.2 — Choose a Plan

You will see three plan options:

```
Free | Team | Enterprise
```

👉 Click **"Create a free organization"**

---

### Step 1.3 — Fill in Organization Details

You will see a form. Fill it exactly like this:

| Field | Value to Type |
|-------|--------------|
| **Organization account name** | `AlumniConnect-AI` |
| **Contact email** | your email address |
| **This organization belongs to** | ✅ Select "My personal account" |

👉 Click **"Next"**

---

### Step 1.4 — Invite Members (Skip for now)

You will see "Add organization members" screen.

👉 Click **"Complete setup"** (you can add members later in Part 3)

---

### Step 1.5 — Verify Organization Created

You should now see your organization page at:
```
https://github.com/AlumniConnect-AI
```

✅ Organization created successfully!

---

## PART 2: GitHub — Transfer Repository

> Transfer your existing `rk9528/Alumniconnect` repo into the new organization.
> **All history, branches, issues, PRs will be preserved.**

### Step 2.1 — Go to Repository Settings

1. Go to: **https://github.com/rk9528/Alumniconnect**
2. Click the **"Settings"** tab (top navigation bar)

---

### Step 2.2 — Find Transfer Section

1. Scroll all the way down to the bottom of Settings
2. You will see a red section called **"Danger Zone"**
3. Find the row: **"Transfer ownership of this repository"**
4. Click the **"Transfer"** button

---

### Step 2.3 — Fill Transfer Form

A dialog box will appear:

**Step 1:** "Specify a new owner"
- Type: `AlumniConnect-AI`
- GitHub will show a suggestion — click on it

**Step 2:** "Type the repository name to confirm"
- Type: `Alumniconnect`

**Step 3:** Click **"I understand, transfer this repository"**

---

### Step 2.4 — Confirm Transfer

GitHub will send you a confirmation email.
- Open your email
- Click **"I understand, transfer this repository"** in the email

---

### Step 2.5 — Verify Transfer

After a few seconds, you will be redirected to:
```
https://github.com/AlumniConnect-AI/Alumniconnect
```

✅ Repository transferred! All commits, branches, and history are intact.

---

### Step 2.6 — Update Your Local Git Remote

Open PowerShell in your project folder and run:

```powershell
git remote set-url origin https://github.com/AlumniConnect-AI/Alumniconnect.git
git remote -v
```

You should see:
```
origin  https://github.com/AlumniConnect-AI/Alumniconnect.git (fetch)
origin  https://github.com/AlumniConnect-AI/Alumniconnect.git (push)
```

---

## PART 3: GitHub — Create Teams & Add Members

### Step 3.1 — Go to Teams Page

1. Go to: **https://github.com/orgs/AlumniConnect-AI/teams**
2. Click **"New team"**

---

### Step 3.2 — Create Team 1: Flutter Developers

Fill the form:

| Field | Value |
|-------|-------|
| **Team name** | `Flutter Developers` |
| **Description** | Flutter app developers for AlumniConnect |
| **Visibility** | Visible |

Click **"Create team"**

Then set permission:
1. Click **"Repositories"** tab
2. Click **"Add repository"**
3. Search and select `AlumniConnect-AI/Alumniconnect`
4. Set permission to: **Write**
5. Click **"Add repository"**

---

### Step 3.3 — Create Team 2: AI/ML Engineers

Repeat the same steps with:

| Field | Value |
|-------|-------|
| **Team name** | `AI ML Engineers` |
| **Description** | Python AI model engineers |
| **Repository permission** | Write |

---

### Step 3.4 — Create Team 3: Backend Engineers

| Field | Value |
|-------|-------|
| **Team name** | `Backend API Engineers` |
| **Description** | FastAPI and backend developers |
| **Repository permission** | Write |

---

### Step 3.5 — Create Team 4: Admins

| Field | Value |
|-------|-------|
| **Team name** | `Admins` |
| **Description** | Project administrators |
| **Repository permission** | Admin |

---

### Step 3.6 — Add Team Members

For each team:
1. Click on the team name
2. Click **"Members"** tab
3. Click **"Add a member"**
4. Type the teammate's GitHub username
5. Click **"Invite"**

They will receive an email invitation to join.

---

## PART 4: GitHub — Branch Protection Rules

This prevents anyone from pushing directly to `main`. All changes must go through a Pull Request.

### Step 4.1 — Go to Branch Protection Settings

1. Go to: **https://github.com/AlumniConnect-AI/Alumniconnect/settings/branches**
2. Click **"Add branch protection rule"**

---

### Step 4.2 — Configure the Rule

Fill in the form exactly:

**Branch name pattern:**
```
main
```

**Check these boxes:**

| Setting | Action |
|---------|--------|
| ✅ Require a pull request before merging | Check this |
| ✅ Require approvals | Check this → set to `1` |
| ✅ Dismiss stale pull request approvals when new commits are pushed | Check this |
| ✅ Require status checks to pass before merging | Check this |
| ✅ Require branches to be up to date before merging | Check this |
| ✅ Do not allow bypassing the above settings | Check this |
| ✅ Restrict who can push to matching branches | Check this |
| ❌ Allow force pushes | Leave unchecked |
| ❌ Allow deletions | Leave unchecked |

---

### Step 4.3 — Add Status Checks

Under "Require status checks":
1. Click inside the search box
2. Search for: `flutter-ci` (from our `ci.yml` file)
3. Select it

---

### Step 4.4 — Save

Click **"Create"** at the bottom.

✅ Branch protection is now active. No one can push directly to `main`.

---

### Step 4.5 — Team Workflow (After Protection)

Every developer must follow this flow:

```bash
# 1. Get latest code
git pull origin main

# 2. Create a feature branch
git checkout -b feature/mentor-match-fix

# 3. Make your changes
# ... write code ...

# 4. Stage and commit
git add .
git commit -m "fix: Firestore timeout in mentor_match_service"

# 5. Push your branch
git push origin feature/mentor-match-fix

# 6. Go to GitHub → Open a Pull Request
# https://github.com/AlumniConnect-AI/Alumniconnect/pulls
# Click "New pull request"
# Select: base=main, compare=feature/mentor-match-fix

# 7. Wait for 1 approval from teammate

# 8. Merge into main
```

---

## PART 5: Render — Deploy Python AI Backend

### Step 5.1 — Create Render Account

1. Go to: **https://render.com**
2. Click **"Get Started"**
3. Click **"Sign in with GitHub"**
4. Authorize Render to access your GitHub account
5. Select **AlumniConnect-AI** organization when prompted

---

### Step 5.2 — Create New Web Service

1. On the Render dashboard, click **"New +"** (top right)
2. Select **"Web Service"**

---

### Step 5.3 — Connect Your Repository

1. You will see a list of your GitHub repositories
2. Find **"AlumniConnect-AI/Alumniconnect"**
3. Click **"Connect"** next to it

> If you don't see it, click **"Configure account"** and grant Render access to the organization.

---

### Step 5.4 — Configure the Web Service

Fill in the deployment settings:

| Field | Value |
|-------|-------|
| **Name** | `alumniconnect-ai` |
| **Region** | Singapore (closest to India) |
| **Branch** | `main` |
| **Root Directory** | `ai-module` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn api.main:app --host 0.0.0.0 --port $PORT` |
| **Plan** | Free |

---

### Step 5.5 — Deploy

Click **"Create Web Service"**

Render will:
1. Pull your code from GitHub
2. Run `pip install -r requirements.txt` (installs PyMuPDF, FastAPI, sentence-transformers, etc.)
3. Start `uvicorn api.main:app`

**This first build takes 5–10 minutes** because it downloads PyTorch and sentence-transformers.

---

### Step 5.6 — Watch Build Logs

You will see a live log like this:
```
==> Cloning from https://github.com/AlumniConnect-AI/Alumniconnect
==> Checking out commit abc123 for branch main
==> Using Python version 3.11.0
==> Running build command: pip install -r requirements.txt
...
Successfully installed fastapi uvicorn pymupdf pdfplumber ...
==> Starting service with: uvicorn api.main:app --host 0.0.0.0 --port $PORT
INFO: Started server process
INFO: Uvicorn running on http://0.0.0.0:10000
```

---

### Step 5.7 — Get Your Live URL

Once deployed, Render gives you a URL like:
```
https://alumniconnect-ai.onrender.com
```

Test it:
```
https://alumniconnect-ai.onrender.com/health
```

You should see:
```json
{"status": "ok", "version": "1.0.0"}
```

✅ Backend is live!

---

## PART 6: Render — Set Environment Variables (Secrets)

> **Never put Firebase keys in your code.** Set them as environment variables on Render.

### Step 6.1 — Go to Environment Settings

1. On Render dashboard, click your service **"alumniconnect-ai"**
2. Click **"Environment"** in the left sidebar

---

### Step 6.2 — Add Each Secret

Click **"Add Environment Variable"** for each one:

| Key | Where to get the value |
|-----|----------------------|
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → General |
| `FIREBASE_CLIENT_EMAIL` | Firebase Console → Project Settings → Service Accounts → Generate Key |
| `FIREBASE_PRIVATE_KEY` | Same JSON file as above (the `private_key` field) |
| `SUPABASE_URL` | Supabase Dashboard → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Settings → API → anon public key |
| `PYTHON_VERSION` | `3.11.0` |

---

### Step 6.3 — Save and Redeploy

After adding all variables:
1. Click **"Save Changes"**
2. Render will automatically redeploy with the new environment variables

---

## PART 7: Connect Render Auto-Deploy to GitHub

This makes Render automatically deploy every time you push to `main`.

### Step 7.1 — Verify Auto-Deploy is ON

1. Go to Render → your service → **"Settings"**
2. Find **"Auto-Deploy"**
3. Make sure it shows **"Yes"** next to `main` branch

---

### Step 7.2 — Get Render Deploy Hook URL

1. Render → your service → **"Settings"**
2. Scroll to **"Deploy Hook"**
3. Click **"Generate Deploy Hook"**
4. Copy the URL — it looks like:
```
https://api.render.com/deploy/srv-xxxxx?key=yyyyy
```

---

### Step 7.3 — Add Deploy Hook to GitHub Actions

1. Go to: **https://github.com/AlumniConnect-AI/Alumniconnect/settings/secrets/actions**
2. Click **"New repository secret"**
3. Fill:

| Field | Value |
|-------|-------|
| **Name** | `RENDER_DEPLOY_HOOK_URL` |
| **Value** | Paste the URL you copied from Render |

4. Click **"Add secret"**

Now the GitHub Actions workflow (`ci.yml`) will trigger a Render deployment automatically when code is merged into `main`.

---

## PART 8: Flutter — Switch to Production URL

Now that Render is live, update your Flutter app to use the production URL.

### Step 8.1 — Open api_config.dart

Open this file:
```
lib/config/api_config.dart
```

### Step 8.2 — Change One Line

Find this line:
```dart
static const ApiEnvironment environment = ApiEnvironment.local;
```

Change it to:
```dart
static const ApiEnvironment environment = ApiEnvironment.production;
```

The production URL `https://alumniconnect-ai.onrender.com` is already configured in the file.

### Step 8.3 — Rebuild the App

```powershell
flutter build apk --release
```

---

## PART 9: Test Everything is Working

### Test 1 — Python Backend Health

Open browser and go to:
```
https://alumniconnect-ai.onrender.com/health
```

Expected response:
```json
{"status": "ok", "version": "1.0.0"}
```

---

### Test 2 — API Docs (Swagger UI)

Open browser and go to:
```
https://alumniconnect-ai.onrender.com/docs
```

You should see a Swagger UI with all endpoints listed:
- `POST /resume/upload`
- `POST /career-twin/analyze`
- `POST /career-gps/analyze`
- `POST /alumni-skill/analyze`
- `POST /mentor-match/analyze`
- `GET /health`

---

### Test 3 — GitHub Actions CI

1. Create a test branch:
```powershell
git checkout -b test/ci-check
git commit --allow-empty -m "test: trigger CI"
git push origin test/ci-check
```

2. Go to GitHub → **Pull Requests** → Create PR from `test/ci-check` → `main`
3. Check the **"Checks"** tab on the PR
4. You should see GitHub Actions running: `flutter-ci`

---

### Test 4 — Full App Flow

1. Build and install the app on your phone/emulator
2. Upload a PDF resume
3. The app should call `https://alumniconnect-ai.onrender.com/resume/upload`
4. Results should appear within 30 seconds

> ⚠️ **Note:** Render's free tier **sleeps after 15 minutes of inactivity**.
> The first request after sleep takes **30–60 seconds** to wake up.
> This is normal. Subsequent requests are fast.

---

## 📋 Quick Reference — All URLs

| Service | URL |
|---------|-----|
| **GitHub Organization** | https://github.com/AlumniConnect-AI |
| **GitHub Repository** | https://github.com/AlumniConnect-AI/Alumniconnect |
| **Render Dashboard** | https://dashboard.render.com |
| **Live API** | https://alumniconnect-ai.onrender.com |
| **API Docs** | https://alumniconnect-ai.onrender.com/docs |
| **Health Check** | https://alumniconnect-ai.onrender.com/health |

---

## ⚠️ Common Issues & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| Render build fails with `torch not found` | PyTorch too large for free tier | Render free tier has 512MB RAM — PyTorch alone is 800MB. Upgrade to Starter plan ($7/mo) or remove torch from requirements |
| App shows "Connection timeout" | Render server sleeping | Wait 60 seconds for cold start, then retry |
| GitHub Actions fails with `flutter not found` | Actions runner needs Flutter setup | Already handled in `ci.yml` with `subosito/flutter-action` |
| `git push` rejected after transfer | Remote URL not updated | Run: `git remote set-url origin https://github.com/AlumniConnect-AI/Alumniconnect.git` |
| Render deploy hook not triggering | Secret not saved | Check GitHub → Settings → Secrets → `RENDER_DEPLOY_HOOK_URL` exists |

---

## 💡 Render Free Tier Limitations

| Limit | Value |
|-------|-------|
| RAM | 512 MB |
| CPU | 0.1 vCPU |
| Sleep after inactivity | 15 minutes |
| Monthly bandwidth | 100 GB |
| Custom domain | ✅ Supported |
| **PyTorch support** | ⚠️ May OOM on free tier |

**Recommendation for Hackathon Demo:**
If PyTorch causes memory issues on Render free tier, use the **Starter plan ($7/month)** which gives 512MB RAM upgrade to 2GB. This ensures SBERT loads correctly.

Alternatively, run the Python server locally during the demo using `start_ai_server.bat` and use the Flutter app with `ApiEnvironment.local`.

---

*AlumniConnect AI | GitHub + Render Setup Guide | Smart India Hackathon 2024*
