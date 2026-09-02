import sys, os
sys.path.insert(0, '.')
from career_twin.engine import CareerTwinEngine
from career_twin.nlp_parser import NLPParser
from tests.test_engine import SAMPLE_PROFILES, SAMPLE_JDS

profile = SAMPLE_PROFILES['data_scientist']
jd = SAMPLE_JDS['ml_engineer_jd']

# Test NLP experience extraction directly on JD text
extracted_jd_exp = NLPParser.extract_experience_years(jd)

# Run engine with req_exp = 0.0 to test auto-fallback vs explicit req_exp = 3.0
result_auto = CareerTwinEngine.analyze(profile, jd, 0.0)
result_explicit = CareerTwinEngine.analyze(profile, jd, 3.0)

print("=" * 60)
print("  DATA SCIENTIST VS ML ENGINEER JD — VERIFICATION REPORT")
print("=" * 60)
print(f"\n1. JD Text Experience String : 'Experience Required: 3+ years'")
print(f"   Extracted JD Experience   : {extracted_jd_exp} years")

cs  = result_auto["career_score"]
sp  = result_auto["skill_profile"]
pp  = result_auto["parsed_profile"]
pj  = result_auto["parsed_jd"]

print(f"\n2. Extracted Candidate Profile Exp : {pp['experience_years']} years")
print(f"   Extracted Candidate Education   : {pp['education']}")
print(f"   Extracted Tech Skills           : {pp['tech_skills']}")

print(f"\n3. Overall Career Score     : {cs['career_score']} / 100")
print(f"   Tier                     : {cs['tier']}")
print(f"   Skill Match Score        : {cs['skill_score']}%")
print(f"   Semantic Similarity      : {cs['semantic_score']}%")
print(f"   Experience Match Score   : {cs['experience_score']}%")
print(f"   Education Score          : {cs['education_score']}%")

print(f"\n4. Matched Skills   : {sp['matched_skills']}")
print(f"   Missing Skills   : {sp['missing_skills']}")
print(f"   Skill Strengths  : {sp['skill_strengths']}")
print(f"   Skill Coverage % : {sp['skill_coverage_%']}%")

print(f"\n5. Recommended Roles:")
for r in sp["suggested_roles"]:
    print(f"   → {r['role']:32} ({r['match_percent']}%)")

print(f"\n6. Recommendations:")
for rec in sp["recommendations"]:
    print(f"   • {rec}")

assert extracted_jd_exp == 3.0, f"Expected 3.0, got {extracted_jd_exp}"
assert cs["career_score"] >= 70, f"Expected score >= 70, got {cs['career_score']}"
assert result_auto["career_score"] == result_explicit["career_score"], "Auto fallback score match failed!"

print("\n✅ VERIFICATION COMPLETE: ALL ASSERTS PASSED SUCCESSFULLY!")
