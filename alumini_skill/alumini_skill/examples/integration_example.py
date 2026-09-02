import os
import sys

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Ensure repository root is in python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))


from skill_gap_analyzer import (
    SkillGapAnalyzer,
    SkillGapRequest,
    get_benchmark_role,
    list_available_roles,
)



def run_pipeline_demo():
    print("=============================================================")
    print("   EduBridge AI — 4 Core AI Modules Interoperability Demo    ")
    print("=============================================================\n")

    # Step 1: Career Twin Engine provides student profile & extracted skills
    student_profile = {
        "student_id": "STU_2026_042",
        "name": "Priya Nair",
        "degree": "B.Tech Computer Science (3rd Year)",
        "career_goal": "AI & Machine Learning Engineer",
        "career_twin_extracted_skills": [
            "Python", "Pandas", "NumPy", "Data Analysis",
            "SQL", "Git", "C++", "Data Structures & Algorithms"
        ]
    }
    print(f"1. [Career Twin Engine] Loaded profile for: {student_profile['name']}")
    print(f"   Target Career: {student_profile['career_goal']}")
    print(f"   Current Skills: {', '.join(student_profile['career_twin_extracted_skills'])}\n")

    # Step 2: Skill Gap Analyzer analyzes profile against benchmark
    analyzer = SkillGapAnalyzer()
    req = SkillGapRequest(
        student_name=student_profile["name"],
        student_skills=student_profile["career_twin_extracted_skills"],
        target_role=student_profile["career_goal"],
        experience_level="Entry Level"
    )
    result = analyzer.analyze(req)

    print("2. [Skill Gap Analyzer Engine Results]")
    print(f"   Placement Readiness Score: {result.placement_readiness_score}%")
    print(f"   Readiness Level: {result.readiness_level}")
    print(f"   Matched Skills ({result.matched_skills_count}): {', '.join([s.skill_name for s in result.matched_skills])}")
    print(f"   Critical Missing Skills: {', '.join([s.skill_name for s in result.missing_critical_skills])}")
    print(f"   Secondary Missing Skills: {', '.join([s.skill_name for s in result.missing_secondary_skills])}\n")

    print("   --- Category Breakdown ---")
    for cat in result.category_breakdown:
        print(f"   • {cat.category}: {cat.matched_count}/{cat.total_count} ({cat.score_percentage}%)")

    print("\n   --- Recommended Courses ---")
    for c in result.recommended_courses[:3]:
        print(f"   • [{c.skill}] {c.title} ({c.provider}) -> {c.url}")

    print("\n   --- Recommended Portfolio Project ---")
    if result.recommended_projects:
        proj = result.recommended_projects[0]
        print(f"   • 🛠️ {proj.title} [{proj.difficulty}]")
        print(f"     Summary: {proj.summary}")
        print(f"     Skills Gained: {', '.join(proj.missing_skills_covered)}")

    # Step 3: Pass missing skills to Mentor Match Engine
    critical_missing_names = [s.skill_name for s in result.missing_critical_skills]
    print("\n3. [Mentor Match Engine Hook]")
    print(f"   Querying Alumni Database for mentors with verified expertise in: {critical_missing_names}")
    print("   -> Suggested Mentor: Alumni Vikram S. (Senior ML Engineer @ Google) - Expertise in PyTorch & Deep Learning")

    # Step 4: Pass gaps & action items to Career GPS Engine
    print("\n4. [Career GPS Engine Hook]")
    print("   Generating personalized weekly milestones based on Skill Gap Action Plan:")
    for idx, item in enumerate(result.action_plan, 1):
        print(f"   {item}")

    print("\n=============================================================")
    print("              End-to-End Pipeline Execution Successful       ")
    print("=============================================================")


if __name__ == "__main__":
    run_pipeline_demo()
