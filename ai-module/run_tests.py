import sys, os
sys.path.insert(0, '.')
import json
from career_twin.engine import CareerTwinEngine
from tests.test_engine import SAMPLE_PROFILES, SAMPLE_JDS

def run(label, profile_key, jd_key, req_exp):
    result = CareerTwinEngine.analyze(
        SAMPLE_PROFILES[profile_key],
        SAMPLE_JDS[jd_key],
        required_experience_years=req_exp
    )
    cs = result["career_score"]
    sp = result["skill_profile"]
    
    # Strip non-ASCII emojis/characters from terminal print statements
    def to_ascii(val):
        return str(val).encode('ascii', errors='ignore').decode('ascii').strip()

    print(f"\n==  {label}  ==")
    print(f"Career Score     : {cs['career_score']} / 100")
    print(f"Tier             : {to_ascii(cs.get('tier', ''))}")
    print(f"Skill Score      : {cs['skill_score']}%")
    print(f"Semantic Score   : {cs['semantic_score']}%")
    print(f"Experience Score : {cs['experience_score']}%")
    print(f"Education Score  : {cs['education_score']}%")
    print(f"Skill Coverage   : {sp['skill_coverage_%']}%")
    print(f"Matched Skills   : {to_ascii(sp['matched_skills'])}")
    print(f"Missing Skills   : {to_ascii(sp['missing_skills'])}")
    print(f"Skill Strengths  : {to_ascii(sp['skill_strengths'])}")
    print("Suggested Roles  :")
    for r in sp["suggested_roles"]:
        print(f"  -> {to_ascii(r['role'])} ({r['match_percent']}%)")
    print("Recommendations  :")
    for rec in sp["recommendations"]:
        print(f"  - {to_ascii(rec)}")

run("TEST 1: Flutter Dev vs Flutter JD", "mobile_dev", "flutter_jd", 2.0)
run("TEST 2: Data Scientist vs ML Engineer JD", "data_scientist", "ml_engineer_jd", 3.0)
run("TEST 3: Fresh Grad vs Frontend JD", "fresh_grad", "frontend_jd", 1.0)
run("TEST 4: Mismatch - Mobile Dev vs ML JD", "mobile_dev", "ml_engineer_jd", 3.0)

print("\nAll tests completed successfully!")
