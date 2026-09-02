import json
from pathlib import Path
from typing import List, Optional, Dict
from app.models.career import CareerDetail
from app.core.config import settings

class CareerDatabase:
    def __init__(self, data_path: Optional[str] = None):
        if not data_path:
            data_path = str(Path(settings.DATA_DIR) / "careers.json")
        self.data_path = data_path
        self._careers: Dict[str, CareerDetail] = {}
        self._load_database()

    def _load_database(self):
        try:
            with open(self.data_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for item in data:
                    career = CareerDetail(**item)
                    self._careers[career.id] = career
        except FileNotFoundError:
            # Fallback if file does not exist during early setup/test
            self._careers = {}
        except Exception as e:
            print(f"Error loading career database: {e}")
            self._careers = {}

    def get_career_by_id(self, career_id: str) -> Optional[CareerDetail]:
        # Perform clean matching
        clean_id = career_id.lower().strip().replace(" ", "-")
        return self._careers.get(clean_id)

    def get_career_by_title(self, title: str) -> Optional[CareerDetail]:
        # Semantic mapping fallback or exact matching
        clean_title = title.lower().strip()
        for career in self._careers.values():
            if career.title.lower() == clean_title:
                return career
        # Try substring matching
        for career in self._careers.values():
            if clean_title in career.title.lower() or career.title.lower() in clean_title:
                return career
        return None

    def list_careers(self) -> List[CareerDetail]:
        return list(self._careers.values())

# Singleton instance
career_db = CareerDatabase()
