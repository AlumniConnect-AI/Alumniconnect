import uvicorn
from dotenv import load_dotenv

# Load environment variables from .env if present
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api_routes import router


app = FastAPI(
    title="Career GPS Engine",
    description="AI-powered career analysis, skill gap detection, and personalized roadmap generation API.",
    version="1.0.0"
)


# CORS middleware for cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register API routes
app.include_router(router)


# Root endpoint
@app.get("/")
def root():
    return {
        "status": "online",
        "service": "Career GPS Engine",
        "version": "1.0.0"
    }


# Health check endpoint
@app.get("/health")
def health():
    return {
        "status": "ok"
    }


# Start FastAPI server
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )