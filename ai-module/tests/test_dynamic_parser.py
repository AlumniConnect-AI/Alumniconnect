import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from pdf_parser.candidate_profile_builder import CandidateProfileBuilder

SAMPLE_RAGHURAMAN_RESUME = """
Raghuraman K
Email: raghuraman@example.com | Phone: +91 9876543210
LinkedIn: https://linkedin.com/in/raghuraman-k | Location: Chennai, India

OBJECTIVE & SUMMARY
Data Analyst with internship experience in data quality, BI pipelines, Python and SQL analytics.

EDUCATION
- MCA — SRM College Ramapuram (2024)
- BCA — D.G. Vaishnav College (2022)
- BS Degree in Data Science — IIT Madras (2025)

SKILLS & TOOLCHAIN
Programming Languages: Python, SQL, PL-SQL, Java, C++
BI Tools & Platforms: Power BI, Microsoft Fabric, Qlik, Talend, Pentaho
Cloud & Automation: Azure, Google Cloud Platform, Power Automate

EXPERIENCE
- Data Analytics Intern — GainInsights Solutions (6 months)
  Worked on data quality audits, BI pipeline automation, and SQL query optimizations.
- Java Developer Intern — Finzly (3 months)
  Developed backend APIs and integrated database models.
- Backend Technical Support Intern — 11S Cricket App (4 months)

PROJECTS
- Power BI/Fabric Translytical Proof of Concept: Built real-time analytics pipeline using Microsoft Fabric and Power BI.
- Qlik File Archive Automation: Automated log archiving scripts using Python.
- TutorConnect: Platform connecting students with verified mentors.

ACHIEVEMENTS & CERTIFICATIONS
- Academic Excellence Award
- IDEATHON Winner
- Best Designer Award
- TNPSC Qualified
- Conference Papers Published
"""

def test_dynamic_resume_parser():
    builder = CandidateProfileBuilder()
    profile = builder.build_profile(SAMPLE_RAGHURAMAN_RESUME)

    print("=== DYNAMIC PARSER TEST RESULT ===")
    print("Success:", profile["success"])
    print("Name:", profile["personalInfo"]["name"])
    print("Email:", profile["personalInfo"]["email"])
    print("Objective:", profile["objective"])
    print("Education Degrees:", [e["degree"] for e in profile["education"]])
    print("Experience Roles:", [e["role"] for e in profile["experience"]])
    print("Extracted Skills:", profile["skills"])
    print("Projects:", [p["name"] for p in profile["projects"]])
    print("Achievements:", profile["achievements"])

    assert profile["success"] == True
    assert "Raghuraman" in profile["personalInfo"]["name"]
    assert "python" in [s.lower() for s in profile["skills"]["languages"]]
    assert "power bi" in [s.lower() for s in profile["skills"]["biTools"]]
    print("\nALL DYNAMIC RESUME PARSER ASSERTIONS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    test_dynamic_resume_parser()
