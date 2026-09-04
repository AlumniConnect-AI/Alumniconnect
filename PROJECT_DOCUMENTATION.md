# Alumniconnect AI — Comprehensive Project Architecture & Workflow Documentation

This document serves as the complete technical and product manual for the Alumniconnect application, detailing every feature, workflow, architectural decision, and AI integration implemented across the platform.

---

## 1. Core Architecture & Data Models

The platform relies on Firebase Firestore for real-time synchronization, utilizing specialized models to drive the dual-role application logic.

### 1.1 Extended User Model (`user_model.dart`)
The foundation of the app relies on the extended `UserModel`. Beyond standard authentication fields, it handles:
- **`role`**: Identifies whether the user is a `"student"` or `"alumni"`. If alumni, it can also be `"pending_alumni_verification"`.
- **`graduationYear`**: Used by automated triggers to upgrade a student to an alumni when their graduation year passes.
- **`collegeId`**: A URL pointing to the user's uploaded college ID card image in Firebase Storage.
- **`verificationStatus`**: Controls access to premium alumni features (e.g., `"pending"`, `"verified"`, `"rejected"`).
- **`consentGiven`**: A boolean flag ensuring GDPR-style consent has been granted for career outcome tracking.
- **`engagementStats`**: Tracks active participation (events attended, mentorships completed).

### 1.2 Career Outcome Pipeline (`outcome_tracking_model.dart`)
This model tracks the lifecycle of a student's employability. 
- It maintains a **5-stage pipeline**: `trained` → `placed` → `3_months_retained` → `6_months_retained` → `12_months_retained`.
- It records self-reported check-ins (`checkIns`) and employer validations (`employerVerification`).
- If a candidate stops reporting or loses employment, their status shifts to `dropped_off`.

### 1.3 Referrals & Mentorships (`referral_model.dart`)
- Separates standard jobs scraped from external sources from internal, high-value **Alumni Referrals** and **Internships**.
- Captures the posting alumni's UID to facilitate 1-on-1 chats between the applicant and the referrer.

---

## 2. The Authentication & Onboarding Flow

The onboarding experience completely forks depending on the user's role selection.

### 2.1 The Registration Split (`register_screen.dart`)
When a new user signs up:
1. **Role Selection**: The user selects "Student" or "Alumni" via a custom chip UI.
2. **Student Flow**: Standard name, email, and password fields are required.
3. **Alumni Flow**: Dynamic UI expansion requires two additional fields:
   - **Graduation Year**: A dropdown to specify their passing year.
   - **College ID Upload**: A strict requirement to upload an image of their college ID card.
4. **Consent Checkbox**: All users must agree to career outcome tracking.
5. **Verification Initialization**: If an alumnus registers, the `AlumniVerificationService` kicks in, writing their status as `pending_alumni_verification` to Firestore.

### 2.2 Role-Based Routing (`main_shell.dart`)
Upon successful login, `main_shell.dart` streams the user's role from Firestore in real-time. It completely transforms the UI based on the role:
- **Student Shell**: Renders 6 bottom navigation tabs (`Home`, `Jobs`, `Events`, `Mentors`, `AI Hub`, `Profile`). Focuses on learning, upskilling, and job hunting.
- **Alumni Shell**: Renders 5 bottom navigation tabs (hiding AI Hub and Mentors, prioritizing `Mentees` and `Referrals`). Focuses on giving back, verifying students, and networking.

---

## 3. The Role-Flip System (Student to Alumni Transition)

A core innovation is the seamless transition of a student to an alumnus. This is managed by the `RoleFlipService` and is triggered in three ways:

### 3.1 Trigger A: Automated Transition
A background chron-job equivalent evaluates the user's `graduationYear`. If the current year exceeds their graduation year, the system automatically prompts them to upload their ID to finalize the transition.

### 3.2 Trigger B: Manual Profile Flip (`profile_screen.dart`)
Students who graduate early or want to force the transition can visit their profile.
- A prominent purple-gradient button reads **"I've graduated — become an alumnus"**.
- Tapping this opens a secure dialog requiring them to update their graduation year and upload their College ID.
- The `RoleFlipService.triggerManualFlip()` is called, immediately stripping student permissions and putting them into the `pending_alumni_verification` state.

### 3.3 Trigger C: The Nudge Banner
If a student is 11 months into their final academic year, the app displays a persistent nudge banner on the Home Screen, preparing them for the transition and capturing their updated contact info before they leave the institution.

---

## 4. Employability & Outcome Tracking

The app acts as a live dashboard for the institution to monitor placement success.

### 4.1 The Retention Timeline (`retention_timeline_widget.dart`)
Featured prominently on the Home Screen, this live, animated widget visually maps the user's career status:
- A horizontal node tree shows progression: **Trained → Placed → 3 Mo → 6 Mo → 12 Mo**.
- **Green nodes** represent achieved milestones.
- **Pulsing nodes** represent current pending milestones.
- **Drop-off Recovery**: If a user is marked as `dropped_off` (e.g., fired or resigned), the timeline highlights the break in amber and immediately surfaces a **"Resume AI Training" CTA** to pull them back into the upskilling ecosystem.

### 4.2 Self-Reporting & Validation (`placement_report_screen.dart` & `employment_verification_screen.dart`)
- **Students**: Periodically prompted to self-report their status (Placed, Interning, Seeking, Dropped Off).
- **Alumni**: If a student claims they were placed at "Google," the system queries all alumni working at Google. Those alumni see an **Employer Verification CTA** on their home screen, allowing them to vouch for the student's employment claim, creating a decentralized validation network.

---

## 5. AI Integrations (The "Add-On" Engine)

The platform heavily leverages AI (via the `AIService` hitting a Python backend) to boost employability.

### 5.1 Shared AI Infrastructure
- **`AISessionCache`**: To minimize expensive API calls and redundant PDF parsing, the app uses a singleton cache. Once a resume is parsed, its JSON structure, extracted skills, and computed ATS scores are stored in memory. The user can jump between the Career Twin Engine and the Mentor Matcher instantly.
- **`AIProcessingLoader`**: A beautifully designed, reusable neon loading widget. It features dynamic state messages ("Parsing PDF...", "Running SBERT...", "Fetching network...") based on an elapsed timer, keeping the user engaged during complex cloud-compute tasks.

### 5.2 AI Career Twin Engine (`career_twin_screen.dart`)
A tool designed to compare a student's resume against a real-world Job Description.
- **Input**: User uploads a PDF resume and pastes a Job Description.
- **Analysis**: The Python backend parses the PDF using NLP and calculates semantic similarity against the JD.
- **Output (ATS Score)**: Returns a unified "ATS Resume Score" based on experience match, education alignment, and exact skill overlaps.
- **Learning Roadmap**: If the engine detects missing skills (e.g., the JD requires AWS, but the resume lacks it), a local function (`_generateLearningRoadmap`) dynamically segments the missing skills into a structured **3-Month Action Plan**:
  - **Month 1**: Fundamentals (First 50% of missing skills)
  - **Month 2**: Advanced Concepts (Remaining 50% of missing skills)
  - **Month 3**: Projects & Portfolio (Building end-to-end apps using the skills learned).

### 5.3 Alumni Mentor Matcher (`alumni_skill_screen.dart`)
Leveraging the `AISessionCache`, this engine finds the perfect alumni mentor for a student.
- **SBERT Matching**: Uses Sentence-BERT (SBERT) on the backend to semantically compare the student's extracted skills, domain, and experience against the database of verified alumni.
- **Fuzzy Domain Matching**: The `MentorMatchService` extracts core keywords from the student's domain (e.g., "Data Analytics") to ensure alumni with matching job titles (e.g., "Data Analyst at TCS") are ranked #1, bypassing rigid string-matching limitations.
- **Unified Scoring**: Pulls the exact same `atsScore` generated by the Career Twin Engine, ensuring a consistent user experience.

---

## 6. Jobs, Referrals & Mentorship Flow

### 6.1 The Unified Jobs Portal (`jobs_list_screen.dart`)
The jobs feed elegantly merges raw, scraped job postings with high-value internal referrals.
- **Color-Coded Badges**: UI badges instantly differentiate between a standard `JOB`, a short-term `INTERNSHIP`, and an exclusive `ALUMNI REFERRAL`.
- **Apply vs. Review**: The `JobDetailScreen` dynamically checks if the current user is the author of the post. 
  - If they are the author, the "Apply Now" button is hidden and replaced with a "View Applicants" dashboard.
  - If they are a standard user, the "Apply Now" button routes them to the application flow or external ATS.

### 6.2 Mentorship Management (`alumni_mentees_screen.dart`)
Alumni manage their give-back initiatives via a dedicated two-tab screen:
- **Tab 1: Pending Requests**: A feed of students requesting mentorship. Alumni can view the student's AI-generated profile and click `Accept` or `Decline`.
- **Tab 2: Active Mentees**: A rolodex of ongoing mentorships. Clicking a mentee opens a direct 1-on-1 chat interface (via `MeetingService` and `ChatService`).

---

## 7. Push Notifications & Reminders

Managed by the `NotificationService`, the system keeps the community active without manual intervention.
- **Transactional Alerts**: Instant push notifications when a student requests mentorship, when a referral is posted, or when an alumni's verification is approved by admins.
- **Lifecycle Nudges**: Automated cron-style push notifications hit placed students at the 3-month, 6-month, and 12-month marks, requesting them to update their employment status in the app, fueling the Outcome Tracking pipeline.
