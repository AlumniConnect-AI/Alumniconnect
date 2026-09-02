import re

# Comprehensive dictionary of technical and soft skills categorized
TECH_SKILLS = {
    # Programming Languages
    "python": r"\bpython\b",
    "dart": r"\bdart\b",
    "javascript": r"\bjavascript\b|\bjs\b",
    # Mobile Development
    "flutter": r"\bflutter\b",
    "react native": r"\breact native\b|\brn\b",
    "android": r"\bandroid\b|\bkotlin\b|\bjava\b",
    "ios": r"\bios\b|\bswift\b|\bobjective-c\b",
    # Frontend Development
    "react": r"\breact\b|\breact\.js\b",
    "angular": r"\bangular\b",
    "vue": r"\bvue\b|\bvue\.js\b",
    "html": r"\bhtml5?\b",
    "css": r"\bcss3?\b|\btailwind\b|\bbootstrap\b",
    # Backend & Databases
    "nodejs": r"\bnode\.js\b|\bnodejs\b",
    "express": r"\bexpress\.js\b|\bexpress\b",
    "django": r"\bddjango\b",
    "firebase": r"\bfirebase\b",
    "supabase": r"\bsubabase\b",
    "postgresql": r"\bpostgresql\b|\bpostgres\b",
    "mongodb": r"\bmongodb\b|\bmongo\b",
    "mysql": r"\bmysql\b",
    "sqlite": r"\bsqlite\b",
    # Cloud & DevOps
    "aws": r"\baws\b|\bamazon web services\b",
    "docker": r"\bdocker\b",
    "kubernetes": r"\bkubernetes\b|\bk8s\b",
    "gcp": r"\bgcp\b|\bgoogle cloud\b",
    "azure": r"\bazure\b",
    # AI & Data Science
    "machine learning": r"\bmachine learning\b|\bml\b",
    "deep learning": r"\bdeep learning\b|\bdl\b",
    "nlp": r"\bnlp\b|\bnatural language processing\b",
    "computer vision": r"\bcomputer vision\b|\bcv\b",
    "tensorflow": r"\btensorflow\b",
    "pytorch": r"\bpytorch\b",
    "scikit-learn": r"\bscikit-learn\b|\bsklearn\b",
    "gemini": r"\bgemini\b",
    "vertex ai": r"\bvertex ai\b",
    "llm": r"\bllm\b|\blarge language model\b",
    # Version Control & Tools
    "git": r"\bgit\b|\bgithub\b",
    "postman": r"\bpostman\b",
}

SOFT_SKILLS = {
    "communication": r"\bcommunication\b|\bverbal\b|\bwritten\b",
    "leadership": r"\bleadership\b|\blead\b|\bmentor\b",
    "teamwork": r"\bteamwork\b|\bcollaborat(e|ive)\b",
    "problem solving": r"\bproblem-solving\b|\bproblem solving\b|\banalytical\b",
    "agile": r"\bagile\b|\bscrum\b",
}

class NLPParser:
    @staticmethod
    def extract_skills(text: str) -> dict:
        """Extracts technical and soft skills from raw text using regex pattern matching."""
        text_lower = text.lower()
        extracted_tech = []
        extracted_soft = []

        # Matches tech skills
        for skill, pattern in TECH_SKILLS.items():
            if re.search(pattern, text_lower):
                extracted_tech.append(skill)
                
        # Matches soft skills
        for skill, pattern in SOFT_SKILLS.items():
            if re.search(pattern, text_lower):
                extracted_soft.append(skill)

        return {
            "tech_skills": sorted(list(set(extracted_tech))),
            "soft_skills": sorted(list(set(extracted_soft)))
        }

    @staticmethod
    def extract_experience_years(text: str) -> float:
        """
        Parses declared experience years from candidate profiles or job descriptions.
        Handles:
          - "3+ years", "3+ yrs", "5+ years"
          - "3 years", "3 yrs"
          - "1-3 years", "3-5 years", "1 to 3 yrs"
          - "minimum 3 years", "min 2 years experience"
          - "experience of 4 years", "experience required: 3+ years"
        """
        text_lower = text.lower()
        candidates = []

        # 1. Range pattern: e.g. "1-3 years", "3 to 5 yrs" -> take minimum bound as starting requirement
        range_matches = re.findall(r"(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)\b", text_lower)
        for rm in range_matches:
            try:
                candidates.append(float(rm[0]))
            except ValueError:
                pass

        # 2. Explicit min/required pattern: e.g. "minimum 3 years", "experience required: 3+ years"
        min_matches = re.findall(r"(?:min|minimum|required|experience\s*(?:required|of|is)?)\s*:?\s*(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)\b", text_lower)
        for mm in min_matches:
            try:
                candidates.append(float(mm))
            except ValueError:
                pass

        # 3. Standard "+ years" / "years" pattern: e.g. "3+ years", "5 yrs"
        std_matches = re.findall(r"(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)\b", text_lower)
        for sm in std_matches:
            try:
                candidates.append(float(sm))
            except ValueError:
                pass

        if candidates:
            return max(candidates)

        return 0.0

    @staticmethod
    def extract_education(text: str) -> list:
        """Extracts education degrees from raw text."""
        text_lower = text.lower()
        degrees = []
        
        education_mappings = {
            "phd": [r"\bph\.?d\.?\b", r"\bdoctor of philosophy\b"],
            "masters": [r"\bm\.?s\.?\b", r"\bm\.?tech\b", r"\bmaster's\b", r"\bmca\b", r"\bmba\b"],
            "bachelors": [r"\bb\.?s\.?\b", r"\bb\.?tech\b", r"\bb\.?e\.?\b", r"\bbachelor's\b", r"\bbca\b", r"\bbba\b"],
        }
        
        for degree, patterns in education_mappings.items():
            for pattern in patterns:
                if re.search(pattern, text_lower):
                    degrees.append(degree)
                    break
        return degrees

    @staticmethod
    def extract_projects(text: str) -> int:
        """Heuristically count the number of projects mentioned in the profile."""
        # Find project section markers or number of times words like 'project' or 'designed' appear
        text_lower = text.lower()
        bullet_points = re.findall(r"•|-|\*", text_lower)
        project_mentions = len(re.findall(r"\bproject\b", text_lower))
        
        # Simple heuristic limit
        if project_mentions > 0:
            return min(project_mentions, 10)
        return len(bullet_points) // 5 if len(bullet_points) > 5 else 0

    @classmethod
    def parse_profile(cls, text: str) -> dict:
        """Parses a full profile string into a structured dictionary."""
        skills = cls.extract_skills(text)
        return {
            "tech_skills": skills["tech_skills"],
            "soft_skills": skills["soft_skills"],
            "experience_years": cls.extract_experience_years(text),
            "education": cls.extract_education(text),
            "projects_count": cls.extract_projects(text)
        }
