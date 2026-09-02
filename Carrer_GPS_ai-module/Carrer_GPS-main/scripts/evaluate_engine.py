import sys
import json
from pathlib import Path

# Add project root to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from app.models.profile import CareerProfile
from app.engine.career_gps import career_gps

from typing import List, Callable, Any

class EvaluationCase:
    def __init__(
        self,
        name: str,
        file: str,
        expected_career: str,
        expected_strengths: List[str],
        expected_gaps: List[str],
        check_roadmap: Callable[[Any], bool]
    ):
        self.name = name
        self.file = file
        self.expected_career = expected_career
        self.expected_strengths = expected_strengths
        self.expected_gaps = expected_gaps
        self.check_roadmap = check_roadmap

# Define test evaluation criteria
EVAL_CASES: List[EvaluationCase] = [
    EvaluationCase(
        name="Beginner Flutter Developer",
        file="examples/flutter_developer.json",
        expected_career="Flutter Developer",
        expected_strengths=["Flutter", "Dart", "Firebase"],
        expected_gaps=["Testing", "CI/CD", "Native Android"],
        check_roadmap=lambda roadmap: "Dart" not in roadmap.phases[0].skills and "Testing" in [s for p in roadmap.phases for s in p.skills]
    ),
    EvaluationCase(
        name="Intermediate Flutter Developer",
        file="examples/flutter_developer_intermediate.json",
        expected_career="Flutter Developer",
        expected_strengths=["Flutter", "Dart", "State Management", "REST APIs", "Git"],
        expected_gaps=["Testing", "CI/CD"],
        check_roadmap=lambda roadmap: "Dart" not in roadmap.phases[0].skills
    ),
    EvaluationCase(
        name="Experienced Backend Developer Switching to Flutter",
        file="examples/backend_developer.json",
        expected_career="Flutter Developer",
        expected_strengths=["Python", "Django", "SQL", "REST APIs", "Git"],
        expected_gaps=["Dart", "Flutter", "State Management"],
        # Roadmap must start with Dart or Flutter basics, not jump directly to testing/CI/CD
        check_roadmap=lambda roadmap: "Dart" in roadmap.phases[0].skills or "Flutter" in roadmap.phases[0].skills
    ),
    EvaluationCase(
        name="CS Student with No Experience",
        file="examples/cs_student_no_exp.json",
        expected_career="Software Engineer",
        expected_strengths=["Python", "Java"],
        expected_gaps=["Git", "SQL", "REST APIs", "Testing", "Clean Architecture"],
        check_roadmap=lambda roadmap: "Git" in roadmap.phases[0].skills or "SQL" in roadmap.phases[0].skills
    ),
    EvaluationCase(
        name="Data Science Student Targeting ML Engineer",
        file="examples/data_scientist.json",
        expected_career="Machine Learning Engineer",
        expected_strengths=["Python", "Pandas", "NumPy"],
        expected_gaps=["PyTorch", "Deep Learning", "Docker", "System Design", "Machine Learning"],
        # Verify that Machine Learning is studied before PyTorch (which is placed in later phases)
        check_roadmap=lambda roadmap: "Machine Learning" in [s for p in roadmap.phases[:2] for s in p.skills] and "PyTorch" in roadmap.phases[-1].skills
    )
]


def run_evaluation():
    print("=" * 60)
    print("CAREER GPS ENGINE EVALUATION SUITE")
    print("=" * 60)
    
    total_cases = len(EVAL_CASES)
    career_match_total = 0.0
    skill_gap_total = 0.0
    roadmap_relevance_total = 0.0
    rec_relevance_total = 0.0
    llm_validity_total = 0.0
    
    results = []
    
    for case in EVAL_CASES:
        name = case.name
        file_path = BASE_DIR / case.file
        
        print(f"\nEvaluating Case: {name}")
        print(f"Loading Profile: {case.file}")
        
        if not file_path.exists():
            print(f"Error: Profile file not found at {file_path}")
            continue
            
        with open(file_path, "r", encoding="utf-8") as f:
            profile_data = json.load(f)
            
        profile = CareerProfile(**profile_data)
        
        # Run analysis
        engine_result = career_gps.generate(profile)
        
        # 1. Career Match Accuracy
        career_match = 1.0 if engine_result.target.career == case.expected_career else 0.0
        career_match_total += career_match
        
        # 2. Skill Gap Accuracy (Intersection over Union of expected gaps vs identified gaps)
        generated_gaps = {g.skill for g in engine_result.skill_gaps if g.gap > 0}
        expected_gaps = set(case.expected_gaps)
        
        intersection = expected_gaps.intersection(generated_gaps)
        union = expected_gaps.union(generated_gaps)
        skill_gap_iou = len(intersection) / len(union) if union else 1.0
        skill_gap_total += skill_gap_iou
        
        # 3. Roadmap Relevance (Check sequencing logic)
        roadmap_ok = 1.0 if case.check_roadmap(engine_result.roadmap) else 0.0
        roadmap_relevance_total += roadmap_ok
        
        # 4. Recommendation Relevance (Check if top recommended projects address actual gaps)
        recs_ok = 1.0
        for project in engine_result.recommended_projects:
            # Recommended project must address at least one of the identified gaps
            addressed_gaps = set(project["skills_addressed"]).intersection(generated_gaps)
            if not addressed_gaps:
                recs_ok = 0.0
        rec_relevance_total += recs_ok
        
        # 5. LLM Output Validity
        # Since the Pydantic schema validation executes successfully without fallbacks, validity is 1.0
        llm_valid = 1.0
        if "fallback" in engine_result.personalization.summary.lower():
            llm_valid = 0.5
        llm_validity_total += llm_valid
        
        results.append({
            "name": name,
            "career_match": career_match,
            "skill_gap_iou": skill_gap_iou,
            "roadmap_relevance": roadmap_ok,
            "rec_relevance": recs_ok,
            "llm_validity": llm_valid
        })
        
        print(f" -> Career Match       : {career_match * 100:.0f}%")
        print(f" -> Skill Gap IoU      : {skill_gap_iou * 100:.1f}%")
        print(f" -> Roadmap Relevance  : {roadmap_ok * 100:.0f}%")
        print(f" -> Project Relevance  : {recs_ok * 100:.0f}%")
        print(f" -> LLM Output Validity: {llm_valid * 100:.0f}%")

    print("\n" + "=" * 60)
    print("EVALUATION METRIC DASHBOARD SUMMARY")
    print("=" * 60)
    print(f"Average Career Match Accuracy : {career_match_total / total_cases * 100:.1f}%")
    print(f"Average Skill Gap IoU Accuracy: {skill_gap_total / total_cases * 100:.1f}%")
    print(f"Average Roadmap Relevance      : {roadmap_relevance_total / total_cases * 100:.1f}%")
    print(f"Average Recommendation Match  : {rec_relevance_total / total_cases * 100:.1f}%")
    print(f"Average LLM Response Validity : {llm_validity_total / total_cases * 100:.1f}%")
    print("=" * 60)

if __name__ == "__main__":
    run_evaluation()
