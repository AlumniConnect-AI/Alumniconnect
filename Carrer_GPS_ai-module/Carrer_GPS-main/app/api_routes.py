from fastapi import APIRouter, HTTPException
from app.models.profile import CareerProfile
from app.models.result import CareerGPSResult
from app.knowledge.career_database import career_db
from app.knowledge.skill_database import skill_db
from app.engine.career_gps import career_gps

router = APIRouter()


@router.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@router.get("/careers")
def list_careers():
    """List all available career paths in the knowledge base."""
    careers = career_db.list_careers()
    return [
        {
            "id": c.id,
            "title": c.title,
            "description": c.description
        }
        for c in careers
    ]


@router.get("/careers/{career_id}")
def get_career(career_id: str):
    """Get details for a specific career by ID."""
    career = career_db.get_career_by_id(career_id)
    if not career:
        raise HTTPException(status_code=404, detail=f"Career '{career_id}' not found")
    return career.model_dump()


@router.get("/skills")
def list_skills():
    """List all known skills and their categories."""
    return {
        "skills": [
            {"name": name, "category": category}
            for name, category in skill_db._skill_categories.items()
        ],
        "total": len(skill_db._skill_categories)
    }


@router.post("/analyze", response_model=CareerGPSResult)
def analyze_career(profile: CareerProfile):
    """
    Analyze a career profile and generate a full Career GPS result.

    Accepts a CareerProfile JSON body and returns:
    - Career readiness score
    - Skill gap analysis
    - Personalized learning roadmap
    - Project recommendations
    - LLM-synthesized explanation
    """
    try:
        result = career_gps.generate(profile)
        return result
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Engine error: {str(e)}")
