"""
Career Twin Engine — Interactive CLI Demo
==========================================
Usage:
  python demo.py                  → run all 4 built-in sample scenarios
  python demo.py --interactive    → type your own profile + JD at the prompt
  python demo.py --scenario 1     → run a single numbered scenario (1-4)

No external API keys. No backend. Pure offline AI.
"""

import sys
import os
import argparse
import textwrap

# ── Make sure the package is importable ──────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from colorama import init, Fore, Back, Style
init(autoreset=True)

from career_twin.engine import CareerTwinEngine

# ─────────────────────────────────────────────────────────────────────────────
#  SAMPLE DATA
# ─────────────────────────────────────────────────────────────────────────────
SAMPLE_SCENARIOS = [
    {
        "title"      : "Flutter Developer vs Flutter Engineer JD",
        "req_exp"    : 2.0,
        "profile"    : """
            Name   : Alagu Aadithan A
            Degree : Bachelor of Computer Applications (BCA) — 2024
            Role   : Flutter Developer | 2 years of experience

            Technical Skills:
              Flutter, Dart, Firebase, Supabase, REST APIs,
              Provider (state management), Git, GitHub,
              Android deployment, iOS deployment

            Projects:
              1. AlumniConnect  – Alumni networking app (Flutter + Firebase + Supabase)
              2. EventHub       – Campus event scheduler with QR check-in
              3. ChatSync       – Real-time chat with image/PDF sharing via Supabase

            Soft Skills: Communication, Teamwork, Agile, Problem Solving
        """,
        "jd": """
            Position : Flutter Developer
            Experience Required : 1-3 years

            Must-Have Skills:
              - Flutter and Dart proficiency
              - Firebase (Authentication, Firestore, Cloud Messaging)
              - Supabase cloud storage preferred
              - REST API integration
              - Git version control
              - Android and iOS deployment

            Nice-to-Have: CI/CD pipelines, Unit testing, Agile workflow
            Communication and Teamwork skills essential.
        """,
    },
    {
        "title"      : "Data Scientist vs ML Engineer JD",
        "req_exp"    : 3.0,
        "profile"    : """
            Name   : Priya Suresh
            Degree : M.Tech in Data Science — IIT Madras — 2022
            Role   : Data Scientist | 4 years of experience

            Technical Skills:
              Python, Machine Learning, Deep Learning, NLP,
              scikit-learn, TensorFlow, PyTorch,
              Pandas, NumPy, SQL, PostgreSQL, Git, Docker

            Projects:
              - Sentiment analysis engine for e-commerce reviews using NLP
              - Customer churn prediction using XGBoost and scikit-learn
              - Image classification pipeline using CNN + TensorFlow
              - Demand forecasting with time-series models

            Soft Skills: Leadership, Communication, Problem Solving, Analytical thinking
        """,
        "jd": """
            Position : Machine Learning Engineer
            Experience Required : 3+ years

            Requirements:
              Python programming (strong)
              Machine Learning and Deep Learning hands-on experience
              NLP experience preferred
              TensorFlow or PyTorch proficiency
              scikit-learn for classical ML models
              Docker for model containerization
              PostgreSQL or MongoDB experience
              Git version control
              Problem solving and analytical thinking
        """,
    },
    {
        "title"      : "Fresh Graduate vs Frontend Developer JD",
        "req_exp"    : 1.0,
        "profile"    : """
            Name   : Ravi Kumar
            Degree : B.Tech in Computer Science — 2025 (fresher, no professional experience)

            Technical Skills: Python, HTML, CSS, JavaScript, React, Git, MySQL

            Projects:
              1. E-commerce website built with HTML, CSS, and JavaScript
              2. Student portal using React and MySQL backend

            Soft Skills: Teamwork, Communication
        """,
        "jd": """
            Position : Frontend Developer
            Experience Required : 1-2 years

            Requirements:
              HTML5, CSS3, JavaScript (ES6+)
              React.js experience
              Familiar with Git and REST APIs
              Good communication and teamwork skills
        """,
    },
    {
        "title"      : "Deliberate Mismatch — Mobile Dev vs ML Engineer JD",
        "req_exp"    : 3.0,
        "profile"    : """
            Name   : Alagu Aadithan A
            Degree : BCA — 2024
            Role   : Flutter Developer | 2 years of experience

            Skills: Flutter, Dart, Firebase, Supabase, Git, Android, iOS
            Soft Skills: Communication, Teamwork
        """,
        "jd": """
            Position : Machine Learning Engineer
            Experience Required : 3 years

            Requirements:
              Python, Machine Learning, Deep Learning, NLP,
              TensorFlow, PyTorch, scikit-learn,
              Docker, MongoDB, PostgreSQL, Git
        """,
    },
]


# ─────────────────────────────────────────────────────────────────────────────
#  TERMINAL FORMATTING HELPERS
# ─────────────────────────────────────────────────────────────────────────────
TERM_WIDTH = 72

def hr(char="─", color=Fore.CYAN):
    print(color + char * TERM_WIDTH + Style.RESET_ALL)

def box_line(text, color=Fore.WHITE, bg=Back.RESET):
    print(color + bg + f"  {text}" + Style.RESET_ALL)

def header(title):
    print()
    print(Fore.CYAN + Style.BRIGHT + "╔" + "═" * (TERM_WIDTH - 2) + "╗")
    padded = title.center(TERM_WIDTH - 2)
    print(Fore.CYAN + Style.BRIGHT + "║" + Fore.WHITE + Style.BRIGHT + padded + Fore.CYAN + "║")
    print(Fore.CYAN + Style.BRIGHT + "╚" + "═" * (TERM_WIDTH - 2) + "╝" + Style.RESET_ALL)

def section(title):
    print()
    print(Fore.YELLOW + Style.BRIGHT + f"  ▶  {title}" + Style.RESET_ALL)
    print(Fore.YELLOW + "  " + "─" * (TERM_WIDTH - 4))

def bullet(label, value, label_color=Fore.CYAN, value_color=Fore.WHITE):
    print(f"  {label_color}{label:<22}{Style.RESET_ALL}{value_color}{value}{Style.RESET_ALL}")

def skill_chips(skills, color=Fore.GREEN):
    if not skills:
        print(f"  {Fore.LIGHTBLACK_EX}  (none){Style.RESET_ALL}")
        return
    line = ""
    for s in skills:
        chip = f" [{s}] "
        if len(line) + len(chip) > TERM_WIDTH - 4:
            print(f"  {color}{line}{Style.RESET_ALL}")
            line = ""
        line += chip
    if line:
        print(f"  {color}{line}{Style.RESET_ALL}")

def score_bar(label, value, max_val=100, width=30):
    filled = int((value / max_val) * width)
    bar_color = (
        Fore.GREEN  if value >= 70 else
        Fore.YELLOW if value >= 45 else
        Fore.RED
    )
    bar = "█" * filled + "░" * (width - filled)
    print(
        f"  {Fore.CYAN}{label:<22}{Style.RESET_ALL}"
        f"{bar_color}{bar}{Style.RESET_ALL}"
        f"  {bar_color}{Style.BRIGHT}{value:>6.1f}%{Style.RESET_ALL}"
    )

def tier_badge(tier, score):
    if score >= 85:
        color = Fore.GREEN + Style.BRIGHT
    elif score >= 70:
        color = Fore.CYAN + Style.BRIGHT
    elif score >= 55:
        color = Fore.YELLOW + Style.BRIGHT
    elif score >= 40:
        color = Fore.YELLOW
    else:
        color = Fore.RED + Style.BRIGHT
    print(f"\n  {color}  {tier}  {Style.RESET_ALL}")


# ─────────────────────────────────────────────────────────────────────────────
#  MAIN RENDERER
# ─────────────────────────────────────────────────────────────────────────────
def render_result(result, scenario_title, req_exp):
    cs = result["career_score"]
    sp = result["skill_profile"]
    pp = result["parsed_profile"]
    pj = result["parsed_jd"]

    header(f"  CAREER TWIN ENGINE — ANALYSIS RESULT  ")

    # ── Title
    print(f"\n  {Fore.WHITE + Style.BRIGHT}Scenario : {Fore.MAGENTA}{scenario_title}{Style.RESET_ALL}")
    print(f"  {Fore.WHITE}JD Req Exp: {Fore.CYAN}{req_exp} years{Style.RESET_ALL}")

    # ── 1. CAREER SCORE ───────────────────────────────────────────────────────
    section("1.  CAREER SCORE")
    score = cs["career_score"]
    score_color = (
        Fore.GREEN  + Style.BRIGHT if score >= 70 else
        Fore.YELLOW + Style.BRIGHT if score >= 50 else
        Fore.RED    + Style.BRIGHT
    )
    big_score = f"{score:.2f} / 100"
    print(f"\n      {score_color}{big_score:^40}{Style.RESET_ALL}")
    tier_badge(cs["tier"], score)

    # ── 7. EXPLANATION PANEL (score breakdown bars) ───────────────────────────
    section("7.  HOW THE SCORE WAS CALCULATED")
    print(
        f"\n  {Fore.LIGHTBLACK_EX}Component scores use the following weights:\n"
        f"  {'Skill Match':22} 40%  — fraction of JD skills the candidate has\n"
        f"  {'Semantic Similarity':22} 25%  — TF-IDF cosine similarity of full texts\n"
        f"  {'Experience Match':22} 20%  — candidate years vs JD required years\n"
        f"  {'Education Bonus':22} 15%  — highest degree level\n"
        f"{Style.RESET_ALL}"
    )
    print()
    score_bar("Skill Match",         cs["skill_score"])
    score_bar("Semantic Similarity",  cs["semantic_score"])
    score_bar("Experience Match",     cs["experience_score"])
    score_bar("Education Bonus",      cs["education_score"])

    exp_note = (
        f"Candidate declared {pp['experience_years']} yrs; JD requires {req_exp} yrs"
        if req_exp > 0 else "No experience requirement stated in JD"
    )
    print(f"\n  {Fore.LIGHTBLACK_EX}  Exp note : {exp_note}{Style.RESET_ALL}")
    edu_found = ", ".join(pp["education"]).upper() if pp["education"] else "Not detected"
    print(f"  {Fore.LIGHTBLACK_EX}  Education: {edu_found}{Style.RESET_ALL}")

    formula = (
        f"Final = ({cs['skill_score']:.1f}×0.40) + "
        f"({cs['semantic_score']:.1f}×0.25) + "
        f"({cs['experience_score']:.1f}×0.20) + "
        f"({cs['education_score']:.1f}×0.15) = {score:.2f}"
    )
    print(f"\n  {Fore.CYAN + Style.BRIGHT}{formula}{Style.RESET_ALL}")

    # ── 2. MATCHED SKILLS ─────────────────────────────────────────────────────
    section("2.  MATCHED SKILLS")
    matched = sp["matched_skills"]
    print(f"  {Fore.LIGHTBLACK_EX}({len(matched)} skills match the JD requirements){Style.RESET_ALL}")
    skill_chips(matched, Fore.GREEN)

    # ── 3. MISSING SKILLS ─────────────────────────────────────────────────────
    section("3.  MISSING SKILLS  (gaps to close)")
    missing = sp["missing_skills"]
    print(f"  {Fore.LIGHTBLACK_EX}({len(missing)} skills required by JD but not in profile){Style.RESET_ALL}")
    skill_chips(missing, Fore.RED)

    # ── 4. SKILL STRENGTHS ────────────────────────────────────────────────────
    section("4.  SKILL STRENGTHS  (you have more than the JD needs)")
    extras = sp["skill_strengths"]
    print(f"  {Fore.LIGHTBLACK_EX}({len(extras)} skills beyond JD requirements — use these to differentiate){Style.RESET_ALL}")
    skill_chips(extras, Fore.CYAN)

    # ── 5. JOB / ROLE SIMILARITY SCORE ───────────────────────────────────────
    section("5.  JOB / ROLE SIMILARITY SCORE")
    sim = cs["semantic_score"]
    score_bar("Text Similarity", sim)
    skill_cov = sp["skill_coverage_%"]
    score_bar("Skill Coverage",  skill_cov)
    combined = round((sim * 0.5 + skill_cov * 0.5), 2)
    print(
        f"\n  {Fore.CYAN}Combined Role-Fit Score : {Style.BRIGHT}{combined:.1f}%{Style.RESET_ALL}  "
        f"{Fore.LIGHTBLACK_EX}(average of text similarity + skill coverage){Style.RESET_ALL}"
    )

    # ── 6. RECOMMENDED CAREER ROLES ───────────────────────────────────────────
    section("6.  RECOMMENDED CAREER ROLES")
    roles = sp["suggested_roles"]
    if roles:
        for i, r in enumerate(roles, 1):
            pct = r["match_percent"]
            role_color = (
                Fore.GREEN  if pct >= 80 else
                Fore.YELLOW if pct >= 50 else
                Fore.RED
            )
            bar = "█" * int(pct / 5) + "░" * (20 - int(pct / 5))
            print(
                f"  {Fore.WHITE}{i}.  {role_color}{r['role']:<38}{Style.RESET_ALL}"
                f"  {role_color}{bar}  {pct}%{Style.RESET_ALL}"
            )
    else:
        print(f"  {Fore.LIGHTBLACK_EX}  Not enough skills to suggest roles.{Style.RESET_ALL}")

    # ── AI RECOMMENDATIONS ────────────────────────────────────────────────────
    section("   AI RECOMMENDATIONS & NEXT STEPS")
    for rec in sp["recommendations"]:
        wrapped = textwrap.wrap(rec, width=TERM_WIDTH - 6)
        for j, line in enumerate(wrapped):
            prefix = "  •" if j == 0 else "   "
            print(f"{Fore.WHITE}{prefix}  {line}{Style.RESET_ALL}")

    # ── LEARNING RESOURCES ────────────────────────────────────────────────────
    if sp["learning_resources"]:
        section("   UPSKILLING RESOURCES FOR MISSING SKILLS")
        for res in sp["learning_resources"]:
            print(f"  {Fore.CYAN}  {res['skill'].title():<20}{Style.RESET_ALL}{Fore.BLUE}{res['resource']}{Style.RESET_ALL}")

    print()
    hr("═", Fore.CYAN)
    print()


# ─────────────────────────────────────────────────────────────────────────────
#  INTERACTIVE MODE
# ─────────────────────────────────────────────────────────────────────────────
def interactive_mode():
    header("  CAREER TWIN ENGINE — INTERACTIVE MODE  ")
    print(f"\n  {Fore.YELLOW}Paste your Profile / Resume text below.")
    print(f"  When done, type END on a line by itself and press Enter.{Style.RESET_ALL}\n")

    lines = []
    while True:
        line = input()
        if line.strip().upper() == "END":
            break
        lines.append(line)
    profile_text = "\n".join(lines)

    print(f"\n  {Fore.YELLOW}Now paste the Job Description text.")
    print(f"  When done, type END on a line by itself and press Enter.{Style.RESET_ALL}\n")

    lines = []
    while True:
        line = input()
        if line.strip().upper() == "END":
            break
        lines.append(line)
    jd_text = "\n".join(lines)

    req_exp_str = input(f"\n  {Fore.CYAN}Required experience years in JD (default 0): {Style.RESET_ALL}").strip()
    req_exp = float(req_exp_str) if req_exp_str else 0.0

    print(f"\n  {Fore.CYAN}Analyzing...{Style.RESET_ALL}")
    result = CareerTwinEngine.analyze(profile_text, jd_text, req_exp)
    render_result(result, "Custom Input", req_exp)


# ─────────────────────────────────────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Career Twin Engine — Standalone CLI Demo"
    )
    parser.add_argument(
        "--interactive", "-i",
        action="store_true",
        help="Enter your own profile and JD interactively"
    )
    parser.add_argument(
        "--scenario", "-s",
        type=int,
        choices=[1, 2, 3, 4],
        default=None,
        help="Run a single sample scenario (1=Flutter, 2=ML, 3=FreshGrad, 4=Mismatch)"
    )
    args = parser.parse_args()

    if args.interactive:
        interactive_mode()
        return

    scenarios_to_run = (
        [SAMPLE_SCENARIOS[args.scenario - 1]]
        if args.scenario
        else SAMPLE_SCENARIOS
    )

    total = len(scenarios_to_run)
    for idx, sc in enumerate(scenarios_to_run, 1):
        if total > 1:
            print(
                f"\n{Fore.MAGENTA + Style.BRIGHT}"
                f"  ══════  SCENARIO {idx}/{total}: {sc['title']}  ══════"
                f"{Style.RESET_ALL}"
            )
        result = CareerTwinEngine.analyze(
            sc["profile"], sc["jd"], sc["req_exp"]
        )
        render_result(result, sc["title"], sc["req_exp"])

    if total > 1:
        header("  ALL SCENARIOS COMPLETE  ")
        print(f"\n  {Fore.GREEN + Style.BRIGHT}All {total} test scenarios ran successfully!{Style.RESET_ALL}")
        print(
            f"  {Fore.CYAN}To run a single scenario : python demo.py --scenario 1{Style.RESET_ALL}\n"
            f"  {Fore.CYAN}To use your own data     : python demo.py --interactive{Style.RESET_ALL}\n"
            f"  {Fore.CYAN}To launch the UI         : streamlit run app.py{Style.RESET_ALL}\n"
        )


if __name__ == "__main__":
    main()
