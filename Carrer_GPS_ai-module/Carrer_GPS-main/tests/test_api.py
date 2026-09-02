import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_list_careers():
    response = client.get("/careers")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    # Each career should have id, title, description
    assert "id" in data[0]
    assert "title" in data[0]
    assert "description" in data[0]


def test_get_career_by_id():
    response = client.get("/careers/flutter-developer")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "flutter-developer"
    assert data["title"] == "Flutter Developer"


def test_get_career_not_found():
    response = client.get("/careers/nonexistent-career")
    assert response.status_code == 404


def test_list_skills():
    response = client.get("/skills")
    assert response.status_code == 200
    data = response.json()
    assert "skills" in data
    assert "total" in data
    assert data["total"] > 0


def test_analyze_career():
    profile = {
        "education": {"degree": "B.Tech", "field": "Computer Science"},
        "current_role": "Student",
        "skills": [
            {"name": "Dart", "level": 4},
            {"name": "Flutter", "level": 4},
            {"name": "Git", "level": 3}
        ],
        "projects": [{
            "name": "E-Commerce App",
            "description": "Flutter app with REST APIs",
            "technologies": ["Flutter", "Dart"]
        }],
        "target_career": "Flutter Developer",
        "target_duration_months": 6
    }
    response = client.post("/analyze", json=profile)
    assert response.status_code == 200
    data = response.json()
    # Verify essential result fields
    assert "readiness" in data
    assert "skill_gaps" in data
    assert "roadmap" in data
    assert "personalization" in data
    assert "next_best_action" in data["personalization"]
    assert "summary" in data["personalization"]
    assert "confidence" in data
    assert data["readiness"]["score"] > 0


def test_analyze_invalid_profile():
    # Missing required fields
    response = client.post("/analyze", json={"current_role": "Student"})
    assert response.status_code == 422
