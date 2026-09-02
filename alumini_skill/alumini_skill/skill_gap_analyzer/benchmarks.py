"""
Industry Benchmark Roles and Required Skill Profiles for EduBridge AI.
Contains curated career role profiles with skill importance levels and category weights.
"""

from typing import Dict, List, Any, Optional

BENCHMARK_ROLES: Dict[str, Dict[str, Any]] = {
    "full_stack_developer": {
        "role_id": "full_stack_developer",
        "role_name": "Full Stack Web Developer",
        "aliases": ["fullstack", "full stack", "web developer", "software engineer - full stack"],
        "description": "Designs and builds end-to-end web applications across frontend, backend, database, and cloud deployments.",
        "core_skills": [
            "JavaScript", "TypeScript", "React", "Node.js", "Express.js",
            "HTML5", "CSS3", "SQL", "MongoDB", "Git", "REST APIs"
        ],
        "secondary_skills": [
            "Next.js", "PostgreSQL", "Tailwind CSS", "Docker", "Redux",
            "CI/CD Pipelines", "Data Structures & Algorithms", "Unit Testing"
        ],
        "bonus_skills": [
            "AWS", "GraphQL", "Redis", "Kubernetes", "Microservices"
        ],
        "category_weights": {
            "Programming Languages": 0.20,
            "Frontend Development": 0.25,
            "Backend & APIs": 0.25,
            "Databases & Caching": 0.15,
            "Cloud & DevOps": 0.10,
            "Tools & Workflow": 0.05
        }
    },
    "ai_ml_engineer": {
        "role_id": "ai_ml_engineer",
        "role_name": "AI & Machine Learning Engineer",
        "aliases": ["ml engineer", "machine learning engineer", "ai engineer", "deep learning engineer"],
        "description": "Develops, trains, evaluates, and deploys intelligent predictive models, deep learning architectures, and LLM applications.",
        "core_skills": [
            "Python", "Machine Learning", "Deep Learning", "PyTorch", "Scikit-Learn",
            "Pandas", "NumPy", "Data Preprocessing", "Data Structures & Algorithms"
        ],
        "secondary_skills": [
            "TensorFlow", "Natural Language Processing", "Computer Vision", "Hugging Face",
            "SQL", "Feature Engineering", "FastAPI", "Docker", "Git"
        ],
        "bonus_skills": [
            "Large Language Models", "Generative AI", "Prompt Engineering", "MLOps", "AWS", "Kubernetes"
        ],
        "category_weights": {
            "Programming Languages": 0.15,
            "AI, ML & Data Science": 0.50,
            "CS Fundamentals": 0.15,
            "Backend & APIs": 0.10,
            "Cloud & DevOps": 0.10
        }
    },
    "data_scientist": {
        "role_id": "data_scientist",
        "role_name": "Data Scientist / Business Analytics",
        "aliases": ["data scientist", "data science", "data analyst", "bi analyst"],
        "description": "Extracts actionable business insights, creates statistical models, and delivers data-driven intelligence through storytelling and visualizations.",
        "core_skills": [
            "Python", "SQL", "Pandas", "NumPy", "Data Analysis", "Data Visualization",
            "Scikit-Learn", "Matplotlib", "Statistics & Probability"
        ],
        "secondary_skills": [
            "Machine Learning", "Seaborn", "R", "Feature Engineering", "Tableau / PowerBI",
            "Git", "Problem Solving"
        ],
        "bonus_skills": [
            "Deep Learning", "Natural Language Processing", "Big Data", "PostgreSQL", "Cloud Analytics"
        ],
        "category_weights": {
            "Programming Languages": 0.20,
            "AI, ML & Data Science": 0.45,
            "Databases & Caching": 0.20,
            "Tools & Workflow": 0.15
        }
    },
    "cloud_devops_engineer": {
        "role_id": "cloud_devops_engineer",
        "role_name": "Cloud & DevOps Engineer",
        "aliases": ["devops", "cloud engineer", "sre", "site reliability engineer", "infrastructure engineer"],
        "description": "Builds, automates, monitors, and scales cloud infrastructure, container orchestration, and CI/CD deployment pipelines.",
        "core_skills": [
            "Linux", "Docker", "Kubernetes", "AWS", "CI/CD Pipelines", "Git",
            "Shell Scripting", "GitHub Actions", "Computer Networks"
        ],
        "secondary_skills": [
            "Terraform", "Google Cloud Platform", "Microsoft Azure", "Nginx", "Python",
            "Monitoring & Logging", "Application Security"
        ],
        "bonus_skills": [
            "Ansible", "Helm", "Go", "Serverless", "Microservices"
        ],
        "category_weights": {
            "Cloud & DevOps": 0.50,
            "Programming Languages": 0.15,
            "CS Fundamentals": 0.15,
            "Tools & Workflow": 0.20
        }
    },
    "backend_engineer": {
        "role_id": "backend_engineer",
        "role_name": "Backend & Microservices Engineer",
        "aliases": ["backend developer", "backend engineer", "server side developer", "api developer"],
        "description": "Architects high-performance server-side business logic, resilient microservices, authentication systems, and database schemas.",
        "core_skills": [
            "Java", "Python", "Node.js", "REST APIs", "PostgreSQL", "MySQL",
            "Data Structures & Algorithms", "Git", "Database Management Systems"
        ],
        "secondary_skills": [
            "Spring Boot", "FastAPI", "MongoDB", "Redis", "Docker", "Microservices",
            "System Design", "Unit Testing", "Object-Oriented Programming"
        ],
        "bonus_skills": [
            "Kubernetes", "gRPC", "WebSockets", "Kafka", "AWS", "GraphQL APIs"
        ],
        "category_weights": {
            "Programming Languages": 0.20,
            "Backend & APIs": 0.35,
            "Databases & Caching": 0.20,
            "CS Fundamentals": 0.15,
            "Cloud & DevOps": 0.10
        }
    },
    "frontend_engineer": {
        "role_id": "frontend_engineer",
        "role_name": "Frontend Web Engineer",
        "aliases": ["frontend developer", "frontend engineer", "ui engineer", "react developer"],
        "description": "Builds high-performance, accessible, responsive, and intuitive web user interfaces with modern client frameworks.",
        "core_skills": [
            "JavaScript", "TypeScript", "React", "HTML5", "CSS3", "Tailwind CSS",
            "Responsive Design", "Git", "REST APIs"
        ],
        "secondary_skills": [
            "Next.js", "Redux", "Vite", "Webpack", "Unit Testing", "Jest",
            "Web Performance Optimization", "CSS Animations"
        ],
        "bonus_skills": [
            "Vue.js", "GraphQL", "Figma to Code", "Progressive Web Apps", "CI/CD Pipelines"
        ],
        "category_weights": {
            "Frontend Development": 0.50,
            "Programming Languages": 0.25,
            "Tools & Workflow": 0.15,
            "Backend & APIs": 0.10
        }
    },
    "mobile_developer": {
        "role_id": "mobile_developer",
        "role_name": "Mobile App Developer (Flutter / Cross-Platform)",
        "aliases": ["mobile developer", "flutter developer", "android developer", "ios developer", "react native developer"],
        "description": "Develops native and cross-platform mobile apps for iOS and Android with sleek UI, offline sync, and REST integration.",
        "core_skills": [
            "Dart", "Flutter", "REST APIs", "Git", "Mobile UI Design", "State Management"
        ],
        "secondary_skills": [
            "Firebase Firestore", "SQLite", "Android SDK", "iOS Swift", "React Native",
            "Push Notifications", "Unit Testing"
        ],
        "bonus_skills": [
            "Kotlin Multiplatform", "CI/CD Pipelines", "App Store Deployment", "GraphQL"
        ],
        "category_weights": {
            "Mobile Development": 0.45,
            "Programming Languages": 0.25,
            "Databases & Caching": 0.15,
            "Tools & Workflow": 0.15
        }
    },
    "cybersecurity_analyst": {
        "role_id": "cybersecurity_analyst",
        "role_name": "Cybersecurity & InfoSec Analyst",
        "aliases": ["security engineer", "cyber security", "soc analyst", "penetration tester"],
        "description": "Protects IT networks, software applications, and sensitive student/enterprise data against security breaches and vulnerabilities.",
        "core_skills": [
            "Computer Networks", "Linux", "Network Security", "Application Security",
            "OWASP Top 10", "Cryptography", "Python"
        ],
        "secondary_skills": [
            "Penetration Testing", "Vulnerability Assessment", "Identity & Access Management",
            "Wireshark / Packet Analysis", "Operating Systems", "Security Auditing"
        ],
        "bonus_skills": [
            "Cloud Security", "SIEM Tools", "Docker Security", "Reverse Engineering"
        ],
        "category_weights": {
            "Cybersecurity": 0.50,
            "CS Fundamentals": 0.25,
            "Programming Languages": 0.15,
            "Cloud & DevOps": 0.10
        }
    }
}


def get_benchmark_role(role_identifier: str) -> Optional[Dict[str, Any]]:
    """
    Finds a benchmark role by ID or by matching against aliases and title.
    """
    if not role_identifier:
        return BENCHMARK_ROLES["full_stack_developer"]
        
    lookup = role_identifier.strip().lower()
    
    # Direct ID match
    if lookup in BENCHMARK_ROLES:
        return BENCHMARK_ROLES[lookup]
        
    # Check aliases and names
    for role_id, data in BENCHMARK_ROLES.items():
        if data["role_name"].lower() == lookup:
            return data
        if any(alias in lookup or lookup in alias for alias in data.get("aliases", [])):
            return data
            
    # Fallback to closest match or default
    return None


def list_available_roles() -> List[Dict[str, Any]]:
    """Returns a list of role summary dictionaries for API catalogs."""
    return [
        {
            "role_id": r["role_id"],
            "role_name": r["role_name"],
            "description": r["description"],
            "core_skills": r["core_skills"],
            "secondary_skills": r["secondary_skills"],
            "total_skills_count": len(r["core_skills"]) + len(r["secondary_skills"])
        }
        for r in BENCHMARK_ROLES.values()
    ]
