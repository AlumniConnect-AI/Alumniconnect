import json
from pathlib import Path
from typing import List, Dict, Optional, Any
from app.core.config import settings
from app.knowledge.skill_database import skill_db

class LearningDatabase:
    def __init__(self, learning_path: Optional[str] = None, projects_path: Optional[str] = None):
        if not learning_path:
            learning_path = str(Path(settings.DATA_DIR) / "learning_paths.json")
        if not projects_path:
            projects_path = str(Path(settings.DATA_DIR) / "projects.json")
            
        self.learning_path = learning_path
        self.projects_path = projects_path
        self._learning_paths: Dict[str, Any] = {}
        self._projects: List[Dict[str, Any]] = []
        self._load_databases()

    def _load_databases(self):
        # Load learning paths
        try:
            with open(self.learning_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self._learning_paths = data.get("learning_paths", {})
        except FileNotFoundError:
            pass
        except Exception as e:
            print(f"Error loading learning paths: {e}")

        # Load projects
        try:
            with open(self.projects_path, 'r', encoding='utf-8') as f:
                self._projects = json.load(f)
        except FileNotFoundError:
            pass
        except Exception as e:
            print(f"Error loading projects database: {e}")

    def get_skill_path_info(self, skill: str) -> Dict[str, Any]:
        normalized = skill_db.normalize_skill_name(skill)
        # Default fallback config if skill is not in learning database
        return self._learning_paths.get(normalized, {
            "hours_per_level": 15,
            "resources": [
                f"Official {normalized} Documentation",
                f"Google Search: Learn {normalized}"
            ],
            "milestones": [
                f"Level 1-2: Understand foundational concepts of {normalized}",
                f"Level 3: Apply {normalized} in basic projects",
                f"Level 4: Master advanced configurations and design patterns of {normalized}"
            ]
        })

    def get_hours_per_level(self, skill: str) -> int:
        info = self.get_skill_path_info(skill)
        return info.get("hours_per_level", 15)

    def get_resources(self, skill: str) -> List[str]:
        info = self.get_skill_path_info(skill)
        return info.get("resources", [])

    def get_milestones(self, skill: str) -> List[str]:
        info = self.get_skill_path_info(skill)
        return info.get("milestones", [])

    def get_all_projects(self) -> List[Dict[str, Any]]:
        return self._projects

    def get_projects_for_skills(self, skills: List[str]) -> List[Dict[str, Any]]:
        normalized_target_skills = {skill_db.normalize_skill_name(s) for s in skills}
        matched_projects = []
        
        for project in self._projects:
            project_skills = {skill_db.normalize_skill_name(s) for s in project.get("skills", [])}
            # Calculate overlapping skills
            overlap = project_skills.intersection(normalized_target_skills)
            if overlap:
                project_copy = project.copy()
                project_copy["relevance_score"] = len(overlap)
                project_copy["matched_skills"] = list(overlap)
                matched_projects.append(project_copy)
                
        # Sort by overlap size descending
        matched_projects.sort(key=lambda x: x["relevance_score"], reverse=True)
        return matched_projects

# Singleton instance
learning_db = LearningDatabase()
