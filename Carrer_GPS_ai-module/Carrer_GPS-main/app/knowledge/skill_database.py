import json
from pathlib import Path
from typing import List, Dict, Optional, Set
from app.core.config import settings

class SkillDatabase:
    def __init__(self, skills_path: Optional[str] = None, matrix_path: Optional[str] = None):
        if not skills_path:
            skills_path = str(Path(settings.DATA_DIR) / "skills.json")
        if not matrix_path:
            matrix_path = str(Path(settings.DATA_DIR) / "career_skill_matrix.json")
        
        self.skills_path = skills_path
        self.matrix_path = matrix_path
        self._aliases: Dict[str, str] = {}
        self._skill_categories: Dict[str, str] = {}
        self._dependencies: Dict[str, List[str]] = {}
        self._load_databases()

    def _load_databases(self):
        # Load skills config
        try:
            with open(self.skills_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Load aliases (keys are lowercase, values are normalized names)
                for alias_k, normalized_v in data.get("aliases", {}).items():
                    self._aliases[alias_k.lower().strip()] = normalized_v
                # Load skill categories
                for skill_entry in data.get("skills", []):
                    name = skill_entry["name"]
                    category = skill_entry["category"]
                    self._skill_categories[name] = category
        except FileNotFoundError:
            pass
        except Exception as e:
            print(f"Error loading skills database: {e}")

        # Load dependency matrix
        try:
            with open(self.matrix_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self._dependencies = data.get("dependencies", {})
        except FileNotFoundError:
            pass
        except Exception as e:
            print(f"Error loading skill matrix: {e}")

    def normalize_skill_name(self, raw_name: str) -> str:
        # 1. Clean raw name
        clean_name = raw_name.strip()
        clean_lower = clean_name.lower()
        
        # 2. Check direct alias match
        if clean_lower in self._aliases:
            return self._aliases[clean_lower]
        
        # 3. Check if there's a match in our catalog of known skills (case-insensitive)
        for known_skill in self._skill_categories.keys():
            if known_skill.lower() == clean_lower:
                return known_skill
                
        # 4. Return title-cased if unknown
        return clean_name.title()

    def get_skill_category(self, skill_name: str) -> str:
        normalized = self.normalize_skill_name(skill_name)
        return self._skill_categories.get(normalized, "Other")

    def get_prerequisites(self, skill_name: str) -> List[str]:
        normalized = self.normalize_skill_name(skill_name)
        return self._dependencies.get(normalized, [])

    def get_all_transitive_prerequisites(self, skill_name: str) -> List[str]:
        normalized = self.normalize_skill_name(skill_name)
        visited: Set[str] = set()
        prereqs: List[str] = []
        
        def dfs(node: str):
            for prereq in self.get_prerequisites(node):
                if prereq not in visited:
                    visited.add(prereq)
                    dfs(prereq)
                    prereqs.append(prereq)
                    
        dfs(normalized)
        return prereqs

    def get_skill_dependency_depth(self, skill_name: str) -> int:
        # Calculates the depth of the dependency tree for ordering
        prereqs = self.get_all_transitive_prerequisites(skill_name)
        return len(prereqs)

# Singleton instance
skill_db = SkillDatabase()
