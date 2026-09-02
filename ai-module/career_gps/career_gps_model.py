import os
import json

class CareerGPSModel:
    """Public Model Entrypoint for Career GPS AI Engine."""

    def __init__(self, knowledge_base_path=None):
        if not knowledge_base_path:
            knowledge_base_path = os.path.join(
                os.path.dirname(__file__), "..", "knowledge", "career_knowledge_base.json"
            )
        try:
            with open(knowledge_base_path, "r", encoding="utf-8") as f:
                self.kb = json.load(f)
        except Exception:
            self.kb = {"job_roles": {}}

    def analyze(self, profile: dict, target_role: str = None) -> dict:
        """
        Generates comprehensive Career GPS guidance from parsed candidate profile:
        - Readiness Score & Tier
        - Recommended Job Roles
        - Skill Gap Analysis
        - 3, 6, 12 Month Growth Timeline Roadmap
        - Recommended Projects & Certifications
        - Salary Progression Estimate & Interview Prep Topics
        """
        cand_skills = profile.get("all_skills", [])
        cand_domain = profile.get("primary_domain", "Mobile Development")
        cand_exp = profile.get("experience", {}).get("total_years", 1.0)

        # Determine target role if not provided
        roles_kb = self.kb.get("job_roles", {})
        if not target_role or target_role not in roles_kb:
            if "flutter" in cand_skills or cand_domain == "Mobile Development":
                target_role = "Mobile App Developer (Flutter)"
            elif "machine learning" in cand_skills or cand_domain == "AI / ML":
                target_role = "AI / ML Engineer"
            elif "sql" in cand_skills or cand_domain == "Data Analytics":
                target_role = "Data Scientist"
            else:
                target_role = "Full-Stack Web Developer"

        role_info = roles_kb.get(target_role, {
            "required_skills": ["python", "git", "rest api", "sql"],
            "recommended_certs": ["AWS Certified Solutions Architect"],
            "salary_estimate": "$75,000 - $130,000",
            "interview_topics": ["Data Structures", "System Design", "Async Programming", "Database Indexing"]
        })

        req_skills = role_info.get("required_skills", [])
        acquired = [s for s in req_skills if s in cand_skills]
        missing = [s for s in req_skills if s not in cand_skills]

        skill_ratio = len(acquired) / len(req_skills) if req_skills else 0.8
        readiness_score = round((skill_ratio * 60.0) + (min(1.0, cand_exp / 3.0) * 40.0), 1)

        tier = "Ready to Apply 🚀" if readiness_score >= 80 else ("Near Ready ⚡" if readiness_score >= 60 else "Developing Skills 📈")

        # 3, 6, 12 Month Growth Timeline Roadmap
        p1_skills = missing[:2] if missing else ["Advanced System Architecture"]
        p2_skills = missing[2:4] if len(missing) > 2 else ["CI/CD Automation & Testing"]

        timeline_roadmap = [
            {
                "timeframe": "Months 1 - 3 (Foundations)",
                "phase": "Phase 1: Core Competency & Skill Gap Mastery",
                "focus_skills": p1_skills,
                "milestone": f"Acquire practical fluency in {', '.join(p1_skills)}."
            },
            {
                "timeframe": "Months 4 - 6 (Advanced Engineering)",
                "phase": "Phase 2: Complex System Architecture & Portfolio",
                "focus_skills": p2_skills,
                "milestone": "Build & deploy full-stack production projects to GitHub."
            },
            {
                "timeframe": "Months 7 - 12 (Career Launch)",
                "phase": "Phase 3: Industry Mastery & Interview Readiness",
                "focus_skills": ["Interview Algorithms", "System Design", "Production Optimization"],
                "milestone": "Target top companies and complete technical screening interviews."
            }
        ]

        # Project recommendations
        projects = [
            {
                "title": f"Production {target_role} Enterprise App",
                "tech": ", ".join(req_skills[:4]),
                "description": "Architect a production-ready application with CI/CD pipeline, unit tests, and live deployment."
            }
        ]

        return {
            "targetRole": target_role,
            "readinessScore": readiness_score,
            "tier": tier,
            "primaryDomain": cand_domain,
            "skillGap": {
                "acquired": acquired,
                "required": req_skills,
                "missing": missing
            },
            "timelineRoadmap": timeline_roadmap,
            "recommendedProjects": projects,
            "recommendedCertifications": role_info.get("recommended_certs", []),
            "salaryEstimate": role_info.get("salary_estimate", "$75,000 - $130,000"),
            "interviewTopics": role_info.get("interview_topics", []),
            "personalizedAdvice": f"🎯 Primary Focus: Build hands-on projects featuring {missing[0] if missing else 'System Design'} to boost candidate readiness above 85%."
        }
