"""
EduBridge AI - Skill Gap Analyzer Microservice API Server.
Exposes REST endpoints for skill gap detection, readiness scoring, and course/project recommendations.
Integrates with Node.js backend, Flutter mobile app, Career Twin, Mentor Match, and Career GPS.
"""

from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Query, Body
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from skill_gap_analyzer.models import (
    SkillGapRequest,
    JobDescriptionGapRequest,
    SkillGapResponse,
    CourseRecommendation,
    ProjectRecommendation,
    BenchmarkRoleInfo,
)
from skill_gap_analyzer.analyzer import SkillGapAnalyzer
from skill_gap_analyzer.benchmarks import BENCHMARK_ROLES, get_benchmark_role, list_available_roles
from skill_gap_analyzer.taxonomy import SKILL_TAXONOMY, normalize_skill, categorize_skill
from skill_gap_analyzer.recommender import CourseRecommender, ProjectRecommender

# Initialize FastAPI App
app = FastAPI(
    title="EduBridge AI - Skill Gap Analyzer API",
    description="AI Engine module for detecting missing student skills, computing placement readiness, and recommending courses & portfolio projects.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS for Flutter frontend and Node.js backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

import os
from fastapi.responses import HTMLResponse, FileResponse

# Initialize Analyzer Engine Singleton
analyzer = SkillGapAnalyzer()

STATIC_DIR = os.path.join(os.path.dirname(__file__), "web")


@app.get("/", response_class=HTMLResponse, tags=["General"])
def root():
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return {
        "service": "EduBridge AI - Skill Gap Analyzer",
        "status": "online",
        "version": "1.0.0",
        "documentation": "/docs",
        "demo": "/demo"
    }


@app.get("/demo", response_class=HTMLResponse, tags=["General"])
def demo_ui():
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse("<h1>Demo UI not found</h1>", status_code=404)



@app.get("/health", tags=["General"])
def health_check():
    return {"status": "healthy", "service": "skill-gap-analyzer", "model_ready": True}


@app.post("/api/v1/skill-gap/analyze", response_model=SkillGapResponse, tags=["Skill Gap Analysis"])
def analyze_skill_gap(request: SkillGapRequest):
    """
    Analyzes a student's skills against a benchmark career role or custom target skills.
    Computes Placement Readiness Score (0-100%), identifies missing critical & secondary skills,
    and returns targeted course and hands-on project recommendations.
    """
    try:
        return analyzer.analyze(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error performing skill gap analysis: {str(e)}")


@app.post("/api/v1/skill-gap/analyze-jd", response_model=SkillGapResponse, tags=["Skill Gap Analysis"])
def analyze_job_description_gap(request: JobDescriptionGapRequest):
    """
    Extracts required technical skills from a raw Job Description text and analyzes
    the student's skill profile against the JD requirements.
    """
    try:
        return analyzer.analyze_from_job_description(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing job description: {str(e)}")


@app.get("/api/v1/skill-gap/roles", response_model=List[BenchmarkRoleInfo], tags=["Benchmarks"])
def get_roles():
    """Returns a list of all available industry benchmark career roles."""
    roles = list_available_roles()
    return [
        BenchmarkRoleInfo(
            role_id=r["role_id"],
            role_name=r["role_name"],
            description=r["description"],
            core_skills=r["core_skills"],
            secondary_skills=r["secondary_skills"],
            total_skills_count=r["total_skills_count"]
        )
        for r in roles
    ]


@app.get("/api/v1/skill-gap/roles/{role_id}", tags=["Benchmarks"])
def get_role_details(role_id: str):
    """Returns detailed requirements and category weights for a specific role."""
    role = get_benchmark_role(role_id)
    if not role:
        raise HTTPException(status_code=404, detail=f"Role '{role_id}' not found.")
    return role


@app.get("/api/v1/skill-gap/taxonomy", tags=["Taxonomy"])
def get_taxonomy():
    """Returns the master skill taxonomy categorized by technical domain."""
    return SKILL_TAXONOMY


@app.post("/api/v1/skill-gap/recommend-courses", response_model=List[CourseRecommendation], tags=["Recommendations"])
def recommend_courses(skills: List[str] = Body(..., example=["Docker", "React", "PyTorch"])):
    """Provides curated course recommendations for specific missing skills."""
    return CourseRecommender.recommend_for_skills(skills, max_per_skill=2)


@app.post("/api/v1/skill-gap/recommend-projects", response_model=List[ProjectRecommendation], tags=["Recommendations"])
def recommend_projects(
    missing_skills: List[str] = Body(..., example=["Redis", "Docker", "Node.js"]),
    target_role: Optional[str] = Query(None, description="Optional target role ID")
):
    """Provides hands-on portfolio project recommendations tailored to bridge missing skill gaps."""
    return ProjectRecommender.recommend_for_gaps(missing_skills, target_role_id=target_role, max_projects=3)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
