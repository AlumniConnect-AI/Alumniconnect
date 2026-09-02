import sys
import os

# ── Resolve ai-module root reliably regardless of uvicorn invocation style ──
# __file__ = .../Alumniconnect-master/ai-module/api/main.py
_api_dir     = os.path.abspath(os.path.dirname(__file__))           # .../ai-module/api
_ai_module_dir = os.path.abspath(os.path.join(_api_dir, ".."))     # .../ai-module
_project_dir = os.path.abspath(os.path.join(_ai_module_dir, "..")) # .../Alumniconnect-master

_alumini_skill_dir = os.path.join(_project_dir, "alumini_skill", "alumini_skill")
_mentor_match_dir  = os.path.join(_project_dir, "ai-module mentor match")

# Insert paths so all sub-packages are importable
for _p in [_ai_module_dir, os.path.abspath(_alumini_skill_dir), os.path.abspath(_mentor_match_dir)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

from pdf_parser.resume_parser import ResumePDFParser
from pdf_parser.candidate_profile_builder import CandidateProfileBuilder
from career_twin.career_match_model import CareerTwinModel
from career_gps.career_gps_model import CareerGPSModel

# ── Import Alumni Skill Gap Analyzer ──────────────────────────────────────────
try:
    from skill_gap_analyzer.analyzer import SkillGapAnalyzer
    from skill_gap_analyzer.models import SkillGapRequest
    _alumni_skill_available = True
    _skill_analyzer = SkillGapAnalyzer()
except ImportError as _e:
    _alumni_skill_available = False
    _skill_analyzer = None
    print(f"[WARN] Alumni Skill Analyzer not available: {_e}")

# ── Import Mentor Match Engine ─────────────────────────────────────────────────
try:
    from mentor_match_engine.engine import MentorMatchEngine
    from mentor_match_engine.models import StudentProfile, MentorProfile
    _mentor_match_available = True
    print("[INFO] Mentor Match Engine (SBERT) loaded successfully.")
except ImportError as _me:
    _mentor_match_available = False
    MentorMatchEngine = None
    StudentProfile = None
    MentorProfile = None
    print(f"[WARN] Mentor Match Engine not available: {_me}")

app = FastAPI(
    title="AlumniConnect AI Engine API",
    description=(
        "Unified AI API powering:\n"
        "- Resume Parser (PDF → Structured Profile)\n"
        "- Career Twin AI (ATS Resume Matcher)\n"
        "- Career GPS AI (Career Roadmap Generator)\n"
        "- Alumni Skill Gap Analyzer (Placement Readiness)\n"
        "- Mentor Match Engine (SBERT Semantic Matching)"
    ),
    version="3.0.0"
)

# Enable CORS for Flutter mobile & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

profile_builder = CandidateProfileBuilder()
gps_model = CareerGPSModel()


# ── Request / Response Schemas ────────────────────────────────────────────────

class TwinRequest(BaseModel):
    profile: Dict[str, Any]
    jd_text: str
    required_exp_years: Optional[float] = 0.0


class GPSRequest(BaseModel):
    profile: Dict[str, Any]
    target_role: Optional[str] = None


class AlumniSkillRequest(BaseModel):
    student_name: Optional[str] = "Student"
    student_skills: List[str]
    target_role: Optional[str] = None
    experience_level: Optional[str] = "Entry Level"
    target_company: Optional[str] = None


class FirestoreAlumniProfile(BaseModel):
    """Alumni profile fetched from Firestore by Flutter and passed to the mentor match engine."""
    uid: str
    name: str
    company: Optional[str] = ""
    designation: Optional[str] = ""
    department: Optional[str] = ""
    skills: Optional[List[str]] = []
    interests: Optional[List[str]] = []
    bio: Optional[str] = ""
    graduation_year: Optional[str] = ""
    experience_years: Optional[float] = 0.0
    photo_url: Optional[str] = None


class MentorMatchRequest(BaseModel):
    """
    Flutter sends the parsed CandidateProfile + Firestore alumni list.
    The engine encodes both sides with SBERT and returns ranked matches.
    """
    candidate_profile: Dict[str, Any]
    alumni_pool: List[FirestoreAlumniProfile]
    top_k: Optional[int] = 5


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "engine": "AlumniConnect Resume Intelligence AI",
        "version": "3.0.0",
        "alumni_skill_available": _alumni_skill_available,
        "mentor_match_available": _mentor_match_available,
    }


@app.post("/resume/upload")
async def upload_resume(file: UploadFile = File(...)):
    """
    Accepts PDF resume file upload.
    Extracts text using PyMuPDF → pdfplumber → pypdf → zlib fallback.
    Returns structured CandidateProfile JSON consumed by all AI engines.

    Error response (422) if PDF text extraction fails — never returns dummy data.
    """
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF resume files are supported.")

    try:
        contents = await file.read()
        extracted_text = ResumePDFParser.extract_text_from_bytes(contents)

        if not extracted_text or len(extracted_text.strip()) < 20:
            raise HTTPException(
                status_code=422,
                detail=(
                    "Could not extract readable text from this PDF. "
                    "Please ensure the PDF contains selectable text (not scanned image). "
                    "Try: File → Save As → PDF (not Print to PDF) in your editor."
                )
            )

        profile = profile_builder.build_profile(extracted_text)

        if not profile.get("success"):
            raise HTTPException(
                status_code=422,
                detail=profile.get("error", "Resume parsing failed.")
            )

        clean_profile = {k: v for k, v in profile.items() if k != "success"}

        print(
            f"[ResumeUpload] Parsed: name={clean_profile.get('personalInfo', {}).get('name')}, "
            f"skills={len(clean_profile.get('allSkills', []))}, "
            f"exp={clean_profile.get('totalExperienceYears')}yrs "
            f"({clean_profile.get('experienceDisplay')}), "
            f"domain={clean_profile.get('primaryDomain')}"
        )

        return {
            "success": True,
            "filename": file.filename,
            "extracted_text_length": len(extracted_text),
            "profile": clean_profile
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Resume parsing error: {str(e)}")


@app.post("/career-twin/analyze")
def analyze_career_twin(req: TwinRequest):
    """
    Analyzes CandidateProfile against a Job Description.
    Computes match score, ATS score, missing skills, and recommendations.
    """
    try:
        profile = req.profile

        # Normalize: if the profile dict still has a nested 'profile' key
        if "profile" in profile and isinstance(profile["profile"], dict):
            profile = profile["profile"]

        # Strip 'success' flag if still present
        if "success" in profile:
            profile = {k: v for k, v in profile.items() if k != "success"}

        print(f"[CareerTwin] Received profile keys: {list(profile.keys())}")
        print(f"[CareerTwin] allSkills count: {len(profile.get('allSkills') or profile.get('all_skills') or [])}")

        result = CareerTwinModel.analyze(
            profile=profile,
            jd_text=req.jd_text,
            required_exp_years=req.required_exp_years or 0.0
        )
        return {
            "success": True,
            "analysis": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Career Twin analysis error: {str(e)}")


@app.post("/career-gps/analyze")
def analyze_career_gps(req: GPSRequest):
    """
    Generates a personalized Career GPS Roadmap from CandidateProfile.
    Returns: 3/6/12-month timeline, skill gap, projects, certifications, salary estimate.
    """
    try:
        result = gps_model.analyze(
            profile=req.profile,
            target_role=req.target_role
        )
        return {
            "success": True,
            "roadmap": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Career GPS analysis error: {str(e)}")


@app.post("/alumni-skill/analyze")
def analyze_alumni_skill(req: AlumniSkillRequest):
    """
    Runs the Alumni Skill Gap Analyzer against a candidate's extracted skills.
    Computes Placement Readiness Score, identifies missing critical skills,
    and returns targeted course and project recommendations.
    """
    if not _alumni_skill_available or _skill_analyzer is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "Alumni Skill Analyzer module not available. "
                "Ensure alumini_skill/alumini_skill is in the Python path."
            )
        )

    try:
        gap_request = SkillGapRequest(
            student_name=req.student_name,
            student_skills=req.student_skills,
            target_role=req.target_role,
            experience_level=req.experience_level or "Entry Level",
            target_company=req.target_company
        )
        response = _skill_analyzer.analyze(gap_request)

        return {
            "success": True,
            "skill_gap": response.model_dump() if hasattr(response, 'model_dump') else response.dict()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Alumni Skill analysis error: {str(e)}")


@app.post("/mentor-match/analyze")
def analyze_mentor_match(req: MentorMatchRequest):
    """
    Runs the SBERT-powered Mentor Match Engine.

    Flutter sends:
      - candidate_profile: Parsed CandidateProfile JSON from /resume/upload
      - alumni_pool: List of alumni profiles fetched from Firestore
      - top_k: Number of top matches to return (default 5)

    Returns:
      - Ranked list of alumni mentor matches with:
        - similarity_score (0.0–1.0 cosine)
        - match_percentage (0–100)
        - matched_skills (overlapping skills)
        - match_reasons (human-readable AI explanations)
        - mentor details (name, company, role, domain, etc.)
    """
    if not _mentor_match_available or MentorMatchEngine is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "Mentor Match Engine (SBERT) not available. "
                "Ensure 'ai-module mentor match' is in the Python path and "
                "sentence-transformers is installed."
            )
        )

    try:
        profile = req.candidate_profile

        # Build StudentProfile from CandidateProfile JSON
        personal_info = profile.get("personalInfo") or {}
        all_skills = profile.get("allSkills") or []
        if not all_skills:
            # Flatten categorized skills
            skills_dict = profile.get("skills") or {}
            for v in skills_dict.values():
                if isinstance(v, list):
                    all_skills.extend([str(s) for s in v])

        edu_list = profile.get("education") or []
        edu_str = ""
        if edu_list:
            first_edu = edu_list[0] if isinstance(edu_list[0], dict) else {}
            degree = first_edu.get("degree", "")
            inst = first_edu.get("institution", "")
            year = first_edu.get("year", "")
            edu_str = f"{degree} — {inst} {year}".strip(" —")

        student = StudentProfile(
            student_id=personal_info.get("email") or "student_001",
            name=personal_info.get("name") or "Candidate",
            department=profile.get("primaryDomain") or "Computer Science",
            skills=[str(s).lower() for s in all_skills if s],
            interests=[profile.get("primaryDomain") or ""],
            career_goals=profile.get("objective") or f"Seeking a role in {profile.get('primaryDomain', 'Technology')}",
            bio=profile.get("objective") or "",
            education=edu_str,
            experience_years=float(profile.get("totalExperienceYears") or 0.0),
        )

        # Build MentorProfile list from Firestore alumni pool
        mentor_pool = []
        for alum in req.alumni_pool:
            skills_list = [s.lower() for s in (alum.skills or []) if s]
            mentor_pool.append(
                MentorProfile(
                    mentor_id=alum.uid,
                    name=alum.name,
                    current_role=alum.designation or "",
                    company=alum.company or "",
                    experience_years=float(alum.experience_years or 0.0),
                    skills=skills_list,
                    interests=alum.interests or [],
                    career_domain=alum.department or "",
                    education=f"Graduated {alum.graduation_year}" if alum.graduation_year else "",
                    bio=alum.bio or "",
                    department=alum.department or "",
                )
            )

        if not mentor_pool:
            return {
                "success": True,
                "mentor_matches": [],
                "total_evaluated": 0,
                "message": "No alumni profiles provided for matching."
            }

        results = MentorMatchEngine.match_student(student, mentor_pool, top_k=req.top_k)

        serialized = []
        for r in results:
            serialized.append({
                "rank": r.rank,
                "uid": r.mentor.mentor_id,
                "name": r.mentor.name,
                "company": r.mentor.company,
                "role": r.mentor.current_role,
                "department": r.mentor.department,
                "career_domain": r.mentor.career_domain,
                "experience_years": r.mentor.experience_years,
                "similarity_score": round(r.similarity_score, 4),
                "match_percentage": round(r.match_percentage, 1),
                "matched_skills": r.matched_skills,
                "match_reasons": r.match_reasons,
            })

        print(
            f"[MentorMatch] Evaluated {len(mentor_pool)} alumni, "
            f"returning top {len(serialized)} matches. "
            f"Best: {serialized[0]['name']} ({serialized[0]['match_percentage']}%)"
            if serialized else "[MentorMatch] No results."
        )

        return {
            "success": True,
            "mentor_matches": serialized,
            "total_evaluated": len(mentor_pool),
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Mentor Match error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
