"""
Intelligent Course & Hands-on Project Recommendation Engine for EduBridge AI.
Maps missing skills and gap profiles to curated online courses and real-world portfolio projects.
"""

from typing import List, Dict, Any, Optional
from .models import CourseRecommendation, ProjectRecommendation
from .taxonomy import normalize_skill

# Curated High-Quality Course Knowledge Base
COURSE_CATALOG: Dict[str, List[Dict[str, Any]]] = {
    "React": [
        {
            "title": "React - The Complete Guide (incl. Next.js, Redux)",
            "provider": "Udemy / Academind",
            "difficulty": "Beginner to Intermediate",
            "duration": "4-6 weeks (40 hrs)",
            "rating": 4.8,
            "url": "https://www.udemy.com/course/react-the-complete-guide-incl-redux/",
            "is_free": False,
            "description": "Comprehensive guide to modern React with Hooks, React Router, Redux Toolkit, and Next.js."
        },
        {
            "title": "Full Stack Open: Modern Web Development (React & Node)",
            "provider": "University of Helsinki",
            "difficulty": "Intermediate",
            "duration": "6-8 weeks",
            "rating": 4.9,
            "url": "https://fullstackopen.com/en/",
            "is_free": True,
            "description": "World-class free course on building modern Single Page Applications with React, Redux, and Node.js backend."
        }
    ],
    "Node.js": [
        {
            "title": "Node.js, Express, MongoDB & More: The Complete Bootcamp",
            "provider": "Udemy",
            "difficulty": "Beginner to Intermediate",
            "duration": "4-5 weeks (35 hrs)",
            "rating": 4.8,
            "url": "https://www.udemy.com/course/nodejs-express-mongodb-bootcamp/",
            "is_free": False,
            "description": "Master Node.js, Express, MongoDB, Mongoose, REST API architecture, and JWT authentication."
        },
        {
            "title": "Server-side Development with NodeJS, Express and MongoDB",
            "provider": "Coursera (HKUST)",
            "difficulty": "Intermediate",
            "duration": "4 weeks",
            "rating": 4.7,
            "url": "https://www.coursera.org/learn/server-side-nodejs",
            "is_free": True,
            "description": "Deep dive into backend server architecture, REST APIs, and database integration with MongoDB."
        }
    ],
    "Python": [
        {
            "title": "Programming for Everybody (Getting Started with Python)",
            "provider": "Coursera / University of Michigan",
            "difficulty": "Beginner",
            "duration": "3-4 weeks",
            "rating": 4.8,
            "url": "https://www.coursera.org/learn/python",
            "is_free": True,
            "description": "Foundational Python programming covering data structures, loops, functions, and file handling."
        },
        {
            "title": "Joy of Computing using Python",
            "provider": "NPTEL / IIT Madras",
            "difficulty": "Beginner to Intermediate",
            "duration": "12 weeks",
            "rating": 4.7,
            "url": "https://nptel.ac.in/courses/106106182",
            "is_free": True,
            "description": "Official NPTEL certified course exploring practical Python problem solving and algorithmic thinking."
        }
    ],
    "Docker": [
        {
            "title": "Docker for Developers & DevOps Bootcamp",
            "provider": "Coursera / freeCodeCamp",
            "difficulty": "Beginner to Intermediate",
            "duration": "2-3 weeks",
            "rating": 4.8,
            "url": "https://www.freecodecamp.org/news/docker-and-containers-guide/",
            "is_free": True,
            "description": "Learn containerization, Dockerfiles, multi-stage builds, Docker Compose, and networking."
        },
        {
            "title": "Docker & Kubernetes: The Practical Guide",
            "provider": "Udemy",
            "difficulty": "Intermediate",
            "duration": "4 weeks (23 hrs)",
            "rating": 4.8,
            "url": "https://www.udemy.com/course/docker-kubernetes-the-practical-guide/",
            "is_free": False,
            "description": "From local Docker containers to production Kubernetes cluster deployment and management."
        }
    ],
    "Kubernetes": [
        {
            "title": "Introduction to Kubernetes (LFS158x)",
            "provider": "edX / Linux Foundation",
            "difficulty": "Intermediate",
            "duration": "4 weeks",
            "rating": 4.7,
            "url": "https://www.edx.org/learn/kubernetes/the-linux-foundation-introduction-to-kubernetes",
            "is_free": True,
            "description": "Official Linux Foundation curriculum covering pods, deployments, services, ingress, and configmaps."
        }
    ],
    "AWS": [
        {
            "title": "AWS Certified Cloud Practitioner & Solutions Architect Prep",
            "provider": "Coursera / AWS Training",
            "difficulty": "Beginner to Intermediate",
            "duration": "4-6 weeks",
            "rating": 4.8,
            "url": "https://www.coursera.org/learn/aws-cloud-practitioner-essentials",
            "is_free": True,
            "description": "Core AWS services including EC2, S3, RDS, Lambda, VPC, IAM, and cloud security architecture."
        }
    ],
    "Machine Learning": [
        {
            "title": "Machine Learning Specialization",
            "provider": "Coursera / DeepLearning.AI & Stanford (Andrew Ng)",
            "difficulty": "Beginner to Intermediate",
            "duration": "8-10 weeks",
            "rating": 4.9,
            "url": "https://www.coursera.org/specializations/machine-learning-introduction",
            "is_free": True,
            "description": "Gold standard foundational ML course: Supervised, Unsupervised learning, Neural Networks, and best practices."
        },
        {
            "title": "Applied Machine Learning Course",
            "provider": "NPTEL / IIT Kharagpur",
            "difficulty": "Intermediate",
            "duration": "12 weeks",
            "rating": 4.7,
            "url": "https://nptel.ac.in/courses/106105267",
            "is_free": True,
            "description": "Rigorous academic formulation of statistical learning, SVMs, decision trees, and model regularization."
        }
    ],
    "Deep Learning": [
        {
            "title": "Deep Learning Specialization",
            "provider": "Coursera / DeepLearning.AI",
            "difficulty": "Intermediate to Advanced",
            "duration": "10-12 weeks",
            "rating": 4.9,
            "url": "https://www.coursera.org/specializations/deep-learning",
            "is_free": True,
            "description": "CNNs, RNNs, Transformers, Optimizers, Batch Norm, and Sequence Models."
        }
    ],
    "PyTorch": [
        {
            "title": "Deep Learning with PyTorch: Zero to GANs",
            "provider": "freeCodeCamp / Jovian",
            "difficulty": "Beginner to Intermediate",
            "duration": "4 weeks",
            "rating": 4.8,
            "url": "https://www.freecodecamp.org/news/learn-pytorch-for-deep-learning/",
            "is_free": True,
            "description": "Hands-on PyTorch tensor operations, autograd, neural network modules, and vision transfer learning."
        }
    ],
    "TensorFlow": [
        {
            "title": "DeepLearning.AI TensorFlow Developer Professional Certificate",
            "provider": "Coursera / DeepLearning.AI",
            "difficulty": "Intermediate",
            "duration": "6-8 weeks",
            "rating": 4.7,
            "url": "https://www.coursera.org/professional-certificates/tensorflow-in-practice",
            "is_free": False,
            "description": "Hands-on TensorFlow 2.x and Keras model training, NLP, and time-series forecasting."
        }
    ],
    "Data Structures & Algorithms": [
        {
            "title": "Data Structures and Algorithms Specialization",
            "provider": "Coursera / UC San Diego",
            "difficulty": "Intermediate",
            "duration": "8-10 weeks",
            "rating": 4.8,
            "url": "https://www.coursera.org/specializations/data-structures-algorithms",
            "is_free": True,
            "description": "Master algorithmic techniques, trees, graphs, dynamic programming, and complexity analysis."
        },
        {
            "title": "Programming, Data Structures and Algorithms Using Python",
            "provider": "NPTEL / IIT Madras",
            "difficulty": "Intermediate",
            "duration": "8 weeks",
            "rating": 4.7,
            "url": "https://nptel.ac.in/courses/106106145",
            "is_free": True,
            "description": "Official NPTEL certified algorithm design and data structure implementation course."
        }
    ],
    "Flutter": [
        {
            "title": "Flutter & Dart - The Complete Guide",
            "provider": "Udemy",
            "difficulty": "Beginner to Intermediate",
            "duration": "5-6 weeks (37 hrs)",
            "rating": 4.8,
            "url": "https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/",
            "is_free": False,
            "description": "Build modern, cross-platform iOS and Android mobile apps with Flutter and Dart from scratch."
        },
        {
            "title": "Flutter Official Codelabs & Documentation Track",
            "provider": "Google Developers",
            "difficulty": "Beginner to Intermediate",
            "duration": "3 weeks",
            "rating": 4.9,
            "url": "https://docs.flutter.dev/get-started/codelab",
            "is_free": True,
            "description": "Step-by-step official Google developer tutorials covering state management, widgets, and HTTP APIs."
        }
    ],
    "SQL": [
        {
            "title": "SQL for Data Science",
            "provider": "Coursera / UC Davis",
            "difficulty": "Beginner",
            "duration": "3 weeks",
            "rating": 4.7,
            "url": "https://www.coursera.org/learn/sql-for-data-science",
            "is_free": True,
            "description": "Relational databases, joins, aggregations, subqueries, and data filtering techniques."
        }
    ],
    "PostgreSQL": [
        {
            "title": "PostgreSQL for Everybody Specialization",
            "provider": "Coursera / University of Michigan",
            "difficulty": "Intermediate",
            "duration": "4 weeks",
            "rating": 4.8,
            "url": "https://www.coursera.org/specializations/postgresql-for-everybody",
            "is_free": True,
            "description": "Advanced SQL, indexing, database design, normalization, JSON support, and full-text search in PostgreSQL."
        }
    ],
    "MongoDB": [
        {
            "title": "MongoDB Basics & Developer Learning Path",
            "provider": "MongoDB University",
            "difficulty": "Beginner to Intermediate",
            "duration": "3 weeks",
            "rating": 4.8,
            "url": "https://learn.mongodb.com/",
            "is_free": True,
            "description": "Official MongoDB developer certification path covering CRUD operations, Aggregation Pipelines, and indexing."
        }
    ],
    "Redis": [
        {
            "title": "Redis for Developers Learning Path",
            "provider": "Redis University (RU101)",
            "difficulty": "Intermediate",
            "duration": "2 weeks",
            "rating": 4.8,
            "url": "https://university.redis.com/",
            "is_free": True,
            "description": "Official Redis training covering in-memory caching, Pub/Sub, Redis Streams, and distributed session management."
        }
    ],
    "CI/CD Pipelines": [
        {
            "title": "DevOps Practices and CI/CD with GitHub Actions",
            "provider": "Coursera / Linux Foundation",
            "difficulty": "Intermediate",
            "duration": "3 weeks",
            "rating": 4.7,
            "url": "https://www.coursera.org/learn/devops-continuous-integration-delivery",
            "is_free": True,
            "description": "Build automated continuous integration, testing, and deployment pipelines using GitHub Actions."
        }
    ],
    "System Design": [
        {
            "title": "System Design for Large-Scale Applications",
            "provider": "Educative / System Design Primer",
            "difficulty": "Intermediate to Advanced",
            "duration": "4-6 weeks",
            "rating": 4.9,
            "url": "https://github.com/donnemartin/system-design-primer",
            "is_free": True,
            "description": "Comprehensive open-source guide to designing scalable distributed systems, load balancing, caching, and sharding."
        }
    ],
    "Cybersecurity": [
        {
            "title": "Google Cybersecurity Professional Certificate",
            "provider": "Coursera / Google",
            "difficulty": "Beginner to Intermediate",
            "duration": "8-12 weeks",
            "rating": 4.8,
            "url": "https://www.coursera.org/professional-certificates/google-cybersecurity",
            "is_free": True,
            "description": "Foundations of cybersecurity, network defense, SIEM tools, Python automation, and incident response."
        }
    ]
}

# Curated Portfolio Projects mapped to missing skills
PROJECT_CATALOG: List[Dict[str, Any]] = [
    {
        "title": "Full-Stack Microservices E-Commerce & Inventory Platform",
        "difficulty": "Advanced",
        "estimated_hours": 35,
        "target_roles": ["full_stack_developer", "backend_engineer"],
        "skills_addressed": ["React", "Node.js", "Express.js", "MongoDB", "Redis", "Docker", "REST APIs", "CI/CD Pipelines"],
        "tech_stack": ["React", "Node.js", "Express", "MongoDB", "Redis", "Docker", "GitHub Actions"],
        "summary": "Build a scalable, containerized microservices platform with user authentication, product catalog caching in Redis, and asynchronous order processing.",
        "key_features": [
            "JWT-based role-based access control (Student/Recruiter/Admin)",
            "Redis cache layer for 10x faster product and profile queries",
            "Dockerized services orchestrated with Docker Compose",
            "Automated CI/CD testing workflow via GitHub Actions"
        ],
        "github_template_or_guide": "https://github.com/topics/fullstack-microservice-template"
    },
    {
        "title": "AI-Powered Resume Analyzer & Skill Gap Detection Engine",
        "difficulty": "Intermediate",
        "estimated_hours": 25,
        "target_roles": ["ai_ml_engineer", "data_scientist"],
        "skills_addressed": ["Python", "Machine Learning", "Scikit-Learn", "Natural Language Processing", "FastAPI", "Pandas", "NumPy"],
        "tech_stack": ["Python", "FastAPI", "Scikit-Learn", "NLTK / SpaCy", "Pandas", "Streamlit"],
        "summary": "Create an NLP pipeline that extracts entities, technical skills, and experience from resumes and computes cosine similarity scores against job requirements.",
        "key_features": [
            "PDF/DOCX text parsing and TF-IDF / SBERT vector embedding generation",
            "Cosine similarity scoring for candidate-job matching",
            "Interactive Streamlit dashboard with radar charts for skill gaps",
            "FastAPI REST endpoint for seamless backend integration"
        ],
        "github_template_or_guide": "https://github.com/topics/resume-parser-nlp"
    },
    {
        "title": "End-to-End LLM RAG System with Semantic Search & Vector DB",
        "difficulty": "Advanced",
        "estimated_hours": 30,
        "target_roles": ["ai_ml_engineer", "full_stack_developer"],
        "skills_addressed": ["Large Language Models", "Generative AI", "PyTorch", "Python", "Docker", "FastAPI"],
        "tech_stack": ["Python", "LangChain / LlamaIndex", "ChromaDB / Pinecone", "FastAPI", "React"],
        "summary": "Develop a Retrieval-Augmented Generation (RAG) assistant that indexes institutional knowledge bases and answers student queries with accurate citations.",
        "key_features": [
            "Document chunking, vector embedding, and hybrid semantic retrieval",
            "Hallucination guardrails and prompt engineering",
            "REST API service with streaming response generation"
        ],
        "github_template_or_guide": "https://github.com/topics/rag-system"
    },
    {
        "title": "Cloud-Native Automated CI/CD Pipeline & Kubernetes Deployment",
        "difficulty": "Advanced",
        "estimated_hours": 25,
        "target_roles": ["cloud_devops_engineer", "backend_engineer"],
        "skills_addressed": ["Docker", "Kubernetes", "AWS", "CI/CD Pipelines", "Linux", "Terraform", "GitHub Actions"],
        "tech_stack": ["Kubernetes (Minikube/EKS)", "Docker", "Terraform", "GitHub Actions", "Prometheus & Grafana"],
        "summary": "Set up a complete infrastructure-as-code repository that automatically builds, tests, and deploys containerized apps to a Kubernetes cluster with monitoring.",
        "key_features": [
            "Terraform scripts for automated cloud resource provisioning",
            "Kubernetes manifest files with Rolling Updates and Horizontal Pod Autoscaling",
            "Prometheus & Grafana dashboard for real-time latency and CPU tracking"
        ],
        "github_template_or_guide": "https://github.com/topics/devops-kubernetes-cicd"
    },
    {
        "title": "EduBridge Mentorship & Career Mobile App in Flutter",
        "difficulty": "Intermediate",
        "estimated_hours": 25,
        "target_roles": ["mobile_developer", "frontend_engineer"],
        "skills_addressed": ["Flutter", "Dart", "Firebase Firestore", "REST APIs", "Git"],
        "tech_stack": ["Flutter", "Dart", "Firebase Auth & Firestore", "Provider / Bloc", "REST API"],
        "summary": "Build a responsive cross-platform mobile app connecting students with alumni mentors featuring chat, booking slots, and personalized roadmaps.",
        "key_features": [
            "Bloc state management with offline persistence",
            "Real-time 1-on-1 messaging and push notifications",
            "Dynamic skill radar chart and career goal milestones"
        ],
        "github_template_or_guide": "https://github.com/topics/flutter-mentorship-app"
    },
    {
        "title": "Secure REST API with JWT Auth, Rate Limiting & PostgreSQL",
        "difficulty": "Intermediate",
        "estimated_hours": 20,
        "target_roles": ["backend_engineer", "full_stack_developer"],
        "skills_addressed": ["PostgreSQL", "REST APIs", "Node.js", "Express.js", "Unit Testing", "Docker"],
        "tech_stack": ["Node.js / Express", "PostgreSQL", "Prisma ORM", "Jest", "Docker"],
        "summary": "Build an enterprise-grade REST backend with strict input validation, database migrations, connection pooling, and automated Jest test suites.",
        "key_features": [
            "Prisma ORM data modeling with PostgreSQL foreign keys and indexing",
            "Express rate-limiter and helmet security headers",
            "90%+ test coverage with Jest unit and integration tests"
        ],
        "github_template_or_guide": "https://github.com/topics/rest-api-postgres-boilerplate"
    }
]


class CourseRecommender:
    """Recommends curated learning resources mapped directly to missing student skills."""

    @staticmethod
    def recommend_for_skills(missing_skills: List[str], max_per_skill: int = 2) -> List[CourseRecommendation]:
        recommendations: List[CourseRecommendation] = []
        seen_titles = set()

        for skill in missing_skills:
            canonical = normalize_skill(skill)
            
            # Find in catalog (exact or partial key match)
            matched_courses = COURSE_CATALOG.get(canonical, [])
            if not matched_courses:
                for cat_skill, courses in COURSE_CATALOG.items():
                    if cat_skill.lower() in canonical.lower() or canonical.lower() in cat_skill.lower():
                        matched_courses = courses
                        break

            # Fallback if no curated course is pre-mapped
            if not matched_courses:
                matched_courses = [
                    {
                        "title": f"Mastering {canonical}: From Fundamentals to Advanced",
                        "provider": "Coursera / NPTEL / FreeCodeCamp",
                        "difficulty": "Intermediate",
                        "duration": "4-6 weeks",
                        "rating": 4.8,
                        "url": f"https://www.coursera.org/search?query={canonical.replace(' ', '%20')}",
                        "is_free": True,
                        "description": f"Targeted learning track to quickly build proficiency and real-world skills in {canonical}."
                    }
                ]

            added_count = 0
            for item in matched_courses:
                if item["title"] not in seen_titles and added_count < max_per_skill:
                    seen_titles.add(item["title"])
                    recommendations.append(
                        CourseRecommendation(
                            skill=canonical,
                            title=item["title"],
                            provider=item["provider"],
                            difficulty=item.get("difficulty", "Beginner to Intermediate"),
                            duration=item.get("duration", "4-6 weeks"),
                            rating=item.get("rating", 4.8),
                            url=item["url"],
                            is_free=item.get("is_free", True),
                            description=item["description"]
                        )
                    )
                    added_count += 1

        return recommendations


class ProjectRecommender:
    """Recommends real-world portfolio projects that specifically bridge identified missing skill gaps."""

    @staticmethod
    def recommend_for_gaps(
        missing_skills: List[str],
        target_role_id: Optional[str] = None,
        max_projects: int = 3
    ) -> List[ProjectRecommendation]:
        normalized_missing = {normalize_skill(s).lower() for s in missing_skills}
        scored_projects = []

        for p in PROJECT_CATALOG:
            project_skills = {s.lower() for s in p["skills_addressed"]}
            overlap = normalized_missing.intersection(project_skills)
            overlap_count = len(overlap)

            # Role relevance bonus
            role_bonus = 1.5 if (target_role_id and target_role_id in p.get("target_roles", [])) else 0.5
            score = (overlap_count * 2.0) + role_bonus

            if overlap_count > 0 or (target_role_id and target_role_id in p.get("target_roles", [])):
                scored_projects.append((score, overlap, p))

        # Sort by highest match score
        scored_projects.sort(key=lambda x: x[0], reverse=True)

        results: List[ProjectRecommendation] = []
        for _, overlap, p in scored_projects[:max_projects]:
            covered = [s for s in p["skills_addressed"] if s.lower() in normalized_missing]
            if not covered:
                covered = p["skills_addressed"][:3]

            results.append(
                ProjectRecommendation(
                    title=p["title"],
                    difficulty=p["difficulty"],
                    estimated_hours=p["estimated_hours"],
                    missing_skills_covered=covered,
                    tech_stack=p["tech_stack"],
                    summary=p["summary"],
                    key_features=p["key_features"],
                    github_template_or_guide=p.get("github_template_or_guide")
                )
            )

        return results
