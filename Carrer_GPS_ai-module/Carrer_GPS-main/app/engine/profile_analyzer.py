from typing import List, Dict, Any, Set
from app.models.profile import CareerProfile, SkillProfile
from app.knowledge.skill_database import skill_db
from app.utils.normalization import deduplicate_skills, extract_skills_from_text

class ProfileAnalyzer:
    def analyze_profile(self, profile: CareerProfile) -> Dict[str, Any]:
        # 1. Normalize and deduplicate self-reported skills
        raw_skills = []
        for sk in profile.skills:
            normalized_name = skill_db.normalize_skill_name(sk.name)
            raw_skills.append({
                "name": normalized_name,
                "level": sk.level,
                "years": sk.years or 0.0,
                "evidence": list(sk.evidence) if sk.evidence else []
            })
        
        # Deduplicate to start with
        user_skills_map = {s["name"]: s for s in deduplicate_skills(raw_skills)}
        
        # 2. Extract skills from projects
        project_skills: Dict[str, List[str]] = {} # skill -> list of project names
        for proj in (profile.projects or []):
            # Check technology tags
            skills_in_project = set()
            for tech in proj.technologies:
                skills_in_project.add(skill_db.normalize_skill_name(tech))
                
            # Scan text description
            if proj.description:
                scanned = extract_skills_from_text(proj.description)
                skills_in_project.update(scanned)
                
            for skill in skills_in_project:
                if skill not in project_skills:
                    project_skills[skill] = []
                project_skills[skill].append(f"Project: {proj.name}")

        # 3. Extract skills from experience
        exp_skills: Dict[str, List[str]] = {} # skill -> list of experiences
        for exp in (profile.experience or []):
            skills_in_exp = set()
            for sk in exp.skills:
                skills_in_exp.add(skill_db.normalize_skill_name(sk))
            
            # Combine role and details if any text scan is wanted
            scanned = extract_skills_from_text(exp.role)
            skills_in_exp.update(scanned)
            
            exp_label = f"Experience as {exp.role}"
            if exp.company:
                exp_label += f" at {exp.company}"
                
            for skill in skills_in_exp:
                if skill not in exp_skills:
                    exp_skills[skill] = []
                exp_skills[skill].append(exp_label)

        # 4. Extract skills from certifications
        cert_skills: Dict[str, List[str]] = {}
        for cert in (profile.certifications or []):
            scanned = extract_skills_from_text(cert.name)
            for skill in scanned:
                if skill not in cert_skills:
                    cert_skills[skill] = []
                cert_label = f"Certification: {cert.name}"
                if cert.issuer:
                    cert_label += f" ({cert.issuer})"
                cert_skills[skill].append(cert_label)

        # 5. Build final effective skills map
        all_skill_names = set(user_skills_map.keys()) | set(project_skills.keys()) | set(exp_skills.keys()) | set(cert_skills.keys())
        
        effective_skills: Dict[str, Dict[str, Any]] = {}
        
        for name in all_skill_names:
            # Find evidence
            evidence = []
            if name in project_skills:
                evidence.extend(project_skills[name])
            if name in exp_skills:
                evidence.extend(exp_skills[name])
            if name in cert_skills:
                evidence.extend(cert_skills[name])
            
            base_level = 0
            base_years = 0.0
            
            if name in user_skills_map:
                base_level = user_skills_map[name]["level"]
                base_years = user_skills_map[name]["years"]
                evidence.extend(user_skills_map[name]["evidence"])
                
            # Clean evidence list (deduplicate)
            evidence = sorted(list(set(evidence)))
            
            # Compute effective level
            # Formula: If we have solid project/experience evidence, increase level by 1.
            # If not listed but we have evidence, assign baseline level 2.
            if base_level > 0:
                if evidence:
                    effective_level = min(5, base_level + 1)
                else:
                    effective_level = base_level
            else:
                # Extracted from project or experience but not self-declared
                effective_level = 2
                
            effective_skills[name] = {
                "name": name,
                "level": effective_level,
                "years": base_years,
                "evidence": evidence,
                "category": skill_db.get_skill_category(name)
            }
            
        # Deduce user career level: Beginner, Intermediate, or Advanced
        # Based on experience and highest skill levels
        total_exp_months = sum(e.duration_months for e in profile.experience) if profile.experience else 0
        max_skill_level = max([s["level"] for s in effective_skills.values()]) if effective_skills else 0
        
        if total_exp_months >= 36 or max_skill_level >= 5:
            career_level = "Advanced"
        elif total_exp_months >= 12 or max_skill_level >= 3:
            career_level = "Intermediate"
        else:
            career_level = "Beginner"
            
        return {
            "effective_skills": effective_skills,
            "career_level": career_level,
            "total_experience_months": total_exp_months
        }

# Singleton instance
profile_analyzer = ProfileAnalyzer()
