"""
Skill Taxonomy and Ontology module for EduBridge AI Skill Gap Analyzer.
Provides normalized skill naming, synonym aliases, domain categorization, and text skill extraction.
"""

import re
from typing import Dict, List, Set, Tuple, Optional

# Master Taxonomy categorized by domain
SKILL_TAXONOMY: Dict[str, List[str]] = {
    "Programming Languages": [
        "Python", "JavaScript", "TypeScript", "Java", "C++", "C", "C#", "Go", "Rust",
        "Ruby", "PHP", "Kotlin", "Swift", "R", "Dart", "Scala", "Shell Scripting", "SQL"
    ],
    "Frontend Development": [
        "React", "Angular", "Vue.js", "Next.js", "HTML5", "CSS3", "Tailwind CSS",
        "Bootstrap", "Redux", "Sass", "Webpack", "Vite", "Responsive Design", "GraphQL"
    ],
    "Backend & APIs": [
        "Node.js", "Express.js", "Django", "FastAPI", "Flask", "Spring Boot",
        "ASP.NET Core", "REST APIs", "GraphQL APIs", "Microservices", "gRPC", "WebSockets"
    ],
    "Databases & Caching": [
        "PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite", "Cassandra",
        "Firebase Firestore", "DynamoDB", "Elasticsearch", "Neo4j", "Prisma", "SQLAlchemy"
    ],
    "Cloud & DevOps": [
        "AWS", "Google Cloud Platform", "Microsoft Azure", "Docker", "Kubernetes",
        "CI/CD Pipelines", "Terraform", "Linux", "Nginx", "GitHub Actions", "Ansible",
        "Serverless", "Monitoring & Logging"
    ],
    "AI, ML & Data Science": [
        "Machine Learning", "Deep Learning", "Natural Language Processing", "Computer Vision",
        "PyTorch", "TensorFlow", "Scikit-Learn", "Pandas", "NumPy", "OpenCV", "Hugging Face",
        "Large Language Models", "Generative AI", "Data Analysis", "Feature Engineering",
        "Prompt Engineering", "Data Visualization", "Matplotlib", "Seaborn"
    ],
    "Mobile Development": [
        "Flutter", "React Native", "Android SDK", "iOS Swift", "Kotlin Multiplatform"
    ],
    "Cybersecurity": [
        "Network Security", "Application Security", "OWASP Top 10", "Penetration Testing",
        "Cryptography", "Identity & Access Management", "Vulnerability Assessment"
    ],
    "CS Fundamentals": [
        "Data Structures & Algorithms", "Object-Oriented Programming", "Operating Systems",
        "Computer Networks", "Database Management Systems", "System Design", "Design Patterns"
    ],
    "Tools & Workflow": [
        "Git", "GitHub", "GitLab", "Jira", "Postman", "Linux/Bash", "Agile/Scrum",
        "Unit Testing", "Jest", "Pytest"
    ],
    "Soft Skills & Professional": [
        "Problem Solving", "Communication", "Team Collaboration", "Critical Thinking",
        "Time Management", "Leadership", "Technical Writing"
    ]
}

# Alias dictionary mapping common variations/abbreviations to canonical skill name
SYNONYM_MAP: Dict[str, str] = {
    # Languages
    "py": "Python",
    "python3": "Python",
    "python 3": "Python",
    "js": "JavaScript",
    "javascript": "JavaScript",
    "ts": "TypeScript",
    "typescript": "TypeScript",
    "golang": "Go",
    "cpp": "C++",
    "c plus plus": "C++",
    "c#": "C#",
    "c sharp": "C#",
    "csharp": "C#",
    "bash": "Shell Scripting",
    "shell": "Shell Scripting",
    "sh": "Shell Scripting",
    "sql": "SQL",

    # Frontend
    "react": "React",
    "reactjs": "React",
    "react.js": "React",
    "react js": "React",
    "next": "Next.js",
    "nextjs": "Next.js",
    "next.js": "Next.js",
    "vue": "Vue.js",
    "vuejs": "Vue.js",
    "vue.js": "Vue.js",
    "angular": "Angular",
    "angularjs": "Angular",
    "html": "HTML5",
    "html5": "HTML5",
    "css": "CSS3",
    "css3": "CSS3",
    "tailwind": "Tailwind CSS",
    "tailwindcss": "Tailwind CSS",
    "redux": "Redux",
    "redux toolkit": "Redux",

    # Backend
    "node": "Node.js",
    "nodejs": "Node.js",
    "node.js": "Node.js",
    "express": "Express.js",
    "expressjs": "Express.js",
    "express.js": "Express.js",
    "django": "Django",
    "fastapi": "FastAPI",
    "fast api": "FastAPI",
    "flask": "Flask",
    "spring": "Spring Boot",
    "springboot": "Spring Boot",
    "spring boot": "Spring Boot",
    "rest": "REST APIs",
    "restful": "REST APIs",
    "rest api": "REST APIs",
    "rest apis": "REST APIs",
    "graphql": "GraphQL",
    "microservices": "Microservices",
    "microservice architecture": "Microservices",

    # Databases
    "postgres": "PostgreSQL",
    "postgresql": "PostgreSQL",
    "psql": "PostgreSQL",
    "mysql": "MySQL",
    "mongo": "MongoDB",
    "mongodb": "MongoDB",
    "redis": "Redis",
    "firebase": "Firebase Firestore",
    "firestore": "Firebase Firestore",
    "elastic search": "Elasticsearch",
    "elasticsearch": "Elasticsearch",

    # Cloud / DevOps
    "aws": "AWS",
    "amazon web services": "AWS",
    "gcp": "Google Cloud Platform",
    "google cloud": "Google Cloud Platform",
    "azure": "Microsoft Azure",
    "docker": "Docker",
    "k8s": "Kubernetes",
    "kubernetes": "Kubernetes",
    "ci/cd": "CI/CD Pipelines",
    "cicd": "CI/CD Pipelines",
    "continuous integration": "CI/CD Pipelines",
    "terraform": "Terraform",
    "linux": "Linux",
    "github actions": "GitHub Actions",

    # AI / ML
    "ml": "Machine Learning",
    "machine learning": "Machine Learning",
    "dl": "Deep Learning",
    "deep learning": "Deep Learning",
    "nlp": "Natural Language Processing",
    "natural language processing": "Natural Language Processing",
    "cv": "Computer Vision",
    "computer vision": "Computer Vision",
    "pytorch": "PyTorch",
    "torch": "PyTorch",
    "tensorflow": "TensorFlow",
    "tf": "TensorFlow",
    "scikit-learn": "Scikit-Learn",
    "sklearn": "Scikit-Learn",
    "pandas": "Pandas",
    "numpy": "NumPy",
    "opencv": "OpenCV",
    "huggingface": "Hugging Face",
    "hugging face": "Hugging Face",
    "llm": "Large Language Models",
    "llms": "Large Language Models",
    "large language models": "Large Language Models",
    "genai": "Generative AI",
    "generative ai": "Generative AI",
    "data analysis": "Data Analysis",
    "eda": "Data Analysis",
    "prompt engineering": "Prompt Engineering",

    # Mobile
    "flutter": "Flutter",
    "react native": "React Native",
    "react-native": "React Native",
    "android": "Android SDK",
    "ios": "iOS Swift",

    # CS Fundamentals
    "dsa": "Data Structures & Algorithms",
    "data structures": "Data Structures & Algorithms",
    "algorithms": "Data Structures & Algorithms",
    "oop": "Object-Oriented Programming",
    "oops": "Object-Oriented Programming",
    "object oriented programming": "Object-Oriented Programming",
    "os": "Operating Systems",
    "operating systems": "Operating Systems",
    "cn": "Computer Networks",
    "networks": "Computer Networks",
    "dbms": "Database Management Systems",
    "system design": "System Design",
    "lld": "Design Patterns",
    "hld": "System Design",

    # Tools
    "git": "Git",
    "github": "GitHub",
    "gitlab": "GitLab",
    "postman": "Postman",
    "pytest": "Pytest",
    "jest": "Jest",
    "unit test": "Unit Testing",
    "unit testing": "Unit Testing"
}

# Inverted mapping: Canonical skill -> Category
CANONICAL_TO_CATEGORY: Dict[str, str] = {}
for category, skills in SKILL_TAXONOMY.items():
    for skill in skills:
        CANONICAL_TO_CATEGORY[skill] = category


def normalize_skill(skill: str) -> str:
    """
    Normalizes a skill name by trimming, lowercasing alias lookup, and returning
    its canonical representation if recognized.
    """
    cleaned = skill.strip()
    lookup = cleaned.lower()
    
    if lookup in SYNONYM_MAP:
        return SYNONYM_MAP[lookup]
    
    # Check if exact match exists in canonical categories
    for canonical in CANONICAL_TO_CATEGORY.keys():
        if canonical.lower() == lookup:
            return canonical
            
    return cleaned.title() if len(cleaned) > 2 else cleaned.upper()


def categorize_skill(skill: str) -> str:
    """Returns the domain category of a given skill."""
    canonical = normalize_skill(skill)
    return CANONICAL_TO_CATEGORY.get(canonical, "Technical Skills")


def extract_skills_from_text(text: str) -> List[str]:
    """
    Extracts recognized technical skills from free-form text (e.g. resume, JD).
    Uses keyword boundary matching and regex.
    """
    if not text:
        return []
        
    found_skills: Set[str] = set()
    lower_text = " " + text.lower() + " "
    
    # Check all aliases and canonical terms
    for alias, canonical in SYNONYM_MAP.items():
        # Match word boundary
        pattern = r"(?<![a-zA-Z0-9_#+])" + re.escape(alias) + r"(?![a-zA-Z0-9_#+])"
        if re.search(pattern, lower_text):
            found_skills.add(canonical)
            
    for canonical in CANONICAL_TO_CATEGORY.keys():
        pattern = r"(?<![a-zA-Z0-9_#+])" + re.escape(canonical.lower()) + r"(?![a-zA-Z0-9_#+])"
        if re.search(pattern, lower_text):
            found_skills.add(canonical)
            
    return sorted(list(found_skills))
