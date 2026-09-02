import re
from typing import List, Dict, Set
from app.knowledge.skill_database import skill_db

def clean_string(text: str) -> str:
    if not text:
        return ""
    return re.sub(r'\s+', ' ', text).strip()

def normalize_text_key(text: str) -> str:
    # Lowercase, strip, replace spaces and underscores with dashes
    if not text:
        return ""
    clean = text.lower().strip()
    clean = re.sub(r'[\s_]+', '-', clean)
    return re.sub(r'[^a-z0-9\-]', '', clean)

def deduplicate_skills(skills_list: List[Dict]) -> List[Dict]:
    # Deduplicates skills, retaining the highest level for duplicates
    seen: Dict[str, Dict] = {}
    for skill in skills_list:
        raw_name = skill.get("name", "")
        normalized = skill_db.normalize_skill_name(raw_name)
        
        level = int(skill.get("level", 0))
        years = float(skill.get("years", 0.0))
        evidence = skill.get("evidence", [])
        if isinstance(evidence, str):
            evidence = [evidence]
            
        if normalized not in seen:
            seen[normalized] = {
                "name": normalized,
                "level": level,
                "years": years,
                "evidence": list(evidence)
            }
        else:
            # Keep highest level
            if level > seen[normalized]["level"]:
                seen[normalized]["level"] = level
            # Combine years and evidence
            seen[normalized]["years"] = max(seen[normalized]["years"], years)
            seen[normalized]["evidence"] = list(set(seen[normalized]["evidence"] + evidence))
            
    return list(seen.values())

def extract_skills_from_text(text: str) -> Set[str]:
    # Scans text and extracts known skills by checking alias and catalog list
    if not text:
        return set()
        
    found_skills: Set[str] = set()
    # Tokenize text into words / short phrases (regex boundaries)
    # Simple word boundary check for each known alias and skill name
    # Compile a quick regex search or substring match
    words = re.findall(r'\b[A-Za-z0-9\.\-\#\+\/]+\b', text)
    
    # We also check combinations (phrases) up to 2 words
    phrases = []
    for i in range(len(words)):
        phrases.append(words[i].lower())
        if i < len(words) - 1:
            phrases.append(f"{words[i]} {words[i+1]}".lower())
            
    # Match phrases against aliases and skill names
    for phrase in phrases:
        # Check alias keys
        if phrase in skill_db._aliases:
            found_skills.add(skill_db._aliases[phrase])
        # Check normalized skills
        for known_skill in skill_db._skill_categories.keys():
            if known_skill.lower() == phrase:
                found_skills.add(known_skill)
                
    return found_skills
