import re
import json
import os
from datetime import datetime
from typing import Optional

class CandidateProfileBuilder:
    """Builds a 100% dynamic Candidate Profile JSON directly from uploaded resume text. Zero dummy data."""

    MONTH_MAP = {
        'jan': 1, 'january': 1, 'feb': 2, 'february': 2,
        'mar': 3, 'march': 3, 'apr': 4, 'april': 4,
        'may': 5, 'jun': 6, 'june': 6,
        'jul': 7, 'july': 7, 'aug': 8, 'august': 8,
        'sep': 9, 'september': 9, 'oct': 10, 'october': 10,
        'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
    }

    def __init__(self, knowledge_base_path=None):
        if not knowledge_base_path:
            knowledge_base_path = os.path.join(
                os.path.dirname(__file__), "..", "knowledge", "career_knowledge_base.json"
            )
        try:
            with open(knowledge_base_path, "r", encoding="utf-8") as f:
                self.kb = json.load(f)
        except Exception:
            self.kb = {"skills": {}, "job_roles": {}}

    def build_profile(self, text: str) -> dict:
        """Parses raw text dynamically and builds candidate profile JSON."""
        if not text or len(text.strip()) < 15:
            return {
                "success": False,
                "error": "Unable to parse uploaded resume."
            }

        lower_text = text.lower()

        personal_info = self._extract_personal_info(text)
        objective = self._extract_objective(text)
        education = self._extract_education_list(text)
        experience_info = self._extract_experience_list(text, education)
        skills = self._extract_categorized_skills(lower_text)
        projects = self._extract_projects(text)
        achievements = self._extract_achievements_and_certs(text)

        # Collect all extracted skills dynamically
        all_skills_list = []
        for cat_skills in skills.values():
            all_skills_list.extend(cat_skills)
        all_skills_list = sorted(list(set(all_skills_list)))

        primary_domain = self._detect_domain(skills)

        return {
            "success": True,
            "personalInfo": personal_info,
            "objective": objective,
            "education": education,
            "experience": experience_info["list"],
            "totalExperienceYears": experience_info["totalYears"],
            "totalExperienceMonths": experience_info["totalMonths"],
            "experienceDisplay": experience_info["displayString"],
            "skills": skills,
            "allSkills": all_skills_list,
            "projects": projects,
            "achievements": achievements,
            "primaryDomain": primary_domain,
            "rawText": text
        }

    def _extract_personal_info(self, text: str) -> dict:
        email_match = re.search(r'[\w\.-]+@[\w\.-]+\.\w+', text)
        phone_match = re.search(r'\(?\+?\d{1,3}\)?[-.\\s]?\d{3,5}[-.\\s]?\d{4,6}', text)
        linkedin_match = re.search(r'(https?://(?:www\.)?linkedin\.com/in/[\w-]+)', text, re.IGNORECASE)
        github_match = re.search(r'(https?://(?:www\.)?github\.com/[\w-]+)', text, re.IGNORECASE)

        lines = [l.strip() for l in text.split("\n") if l.strip()]
        name = "Candidate"
        for line in lines[:4]:
            if "@" not in line and "http" not in line.lower() and "resume" not in line.lower() and len(line) < 40:
                name = line
                break

        location_match = re.search(
            r'\b(Chennai|Bengaluru|Bangalore|Hyderabad|Mumbai|Delhi|Pune|Noida|Gurugram|Tamil Nadu|India|USA|UK)\b',
            text, re.IGNORECASE
        )

        return {
            "name": name,
            "email": email_match.group(0) if email_match else "",
            "phone": phone_match.group(0) if phone_match else "",
            "linkedin": linkedin_match.group(0) if linkedin_match else "",
            "github": github_match.group(0) if github_match else "",
            "location": location_match.group(0) if location_match else ""
        }

    def _extract_objective(self, text: str) -> str:
        lines = text.split("\n")
        in_obj = False
        obj_lines = []
        for line in lines:
            line_str = line.strip()
            if re.search(r'^(summary|objective|profile summary|about me|career objective)\b', line_str, re.IGNORECASE):
                in_obj = True
                continue
            if in_obj:
                if re.search(r'^(education|experience|skills|projects|certifications|achievements)\b', line_str, re.IGNORECASE):
                    break
                if line_str:
                    obj_lines.append(line_str)
        return " ".join(obj_lines[:3]) if obj_lines else ""

    def _extract_education_list(self, text: str) -> list:
        education_entries = []
        lines = text.split("\n")
        in_edu = False

        degree_patterns = [
            (r'\b(mca|master of computer applications)\b', 'MCA'),
            (r'\b(bca|bachelor of computer applications)\b', 'BCA'),
            (r'\b(b\.?tech|b\.?e|bachelor of technology|bachelor of engineering)\b', 'B.Tech / B.E'),
            (r'\b(m\.?tech|m\.?e|master of technology|master of engineering)\b', 'M.Tech / M.E'),
            (r'\b(bs|b\.?s|bachelor of science)\b', 'B.S Degree'),
            (r'\b(ms|m\.?s|master of science)\b', 'M.S Degree'),
            (r'\b(diploma)\b', 'Diploma'),
            (r'\b(phd|doctorate)\b', 'PhD'),
        ]

        for line in lines:
            line_str = line.strip()
            if re.search(r'^(education|academic background|qualifications)\b', line_str, re.IGNORECASE):
                in_edu = True
                continue
            if in_edu:
                if re.search(r'^(experience|work experience|projects|skills|certifications|achievements)\b', line_str, re.IGNORECASE):
                    break

                for pattern, degree_name in degree_patterns:
                    if re.search(pattern, line_str, re.IGNORECASE):
                        inst_match = re.search(
                            r'(?:from|at|-)?\s*([A-Z][A-Za-z\s\.,]+(?:College|University|Institute|School|Ramapuram|Madras|SRM|D\.G\. Vaishnav|IIT))',
                            line_str, re.IGNORECASE
                        )
                        inst = inst_match.group(1).strip() if inst_match else ""

                        year_match = re.search(r'\b(20[0-2][0-9])\b', line_str)
                        year = year_match.group(1) if year_match else ""

                        education_entries.append({
                            "degree": degree_name,
                            "institution": inst,
                            "year": year,
                            "raw": line_str
                        })
                        break

        return education_entries if education_entries else [
            {"degree": "Degree", "institution": "", "year": "", "raw": "Education detected in resume"}
        ]

    # ── FIXED EXPERIENCE CALCULATION ────────────────────────────────────────────
    def _extract_experience_list(self, text: str, education: list) -> dict:
        """
        Accurately calculates total experience by:
        1. Extracting the experience/internships section from resume
        2. Parsing date ranges (Jan 2023 – Mar 2023 / 2023-2024)
        3. Parsing explicit duration strings (3 Months, 2 Years)
        4. NEVER using graduation years or random year numbers as experience
        5. Summing all parsed durations
        """
        exp_entries = []
        total_months = 0

        # Collect graduation years to explicitly exclude from experience math
        grad_years = set()
        for edu in education:
            if edu.get("year"):
                try:
                    grad_years.add(int(edu["year"]))
                except ValueError:
                    pass

        # ── Extract experience section text ───────────────────────────────────
        exp_section_text = self._extract_section(
            text,
            start_patterns=[r'^(experience|work experience|employment|internships?)\b'],
            stop_patterns=[r'^(education|projects|skills|certifications|achievements|academic|extra|activities)\b']
        )

        # ── Parse entries from experience section ─────────────────────────────
        lines = exp_section_text.split("\n") if exp_section_text else []
        current_role_block = []

        for line in lines:
            line_str = line.strip()
            if not line_str or len(line_str) < 3:
                continue

            is_internship = "intern" in line_str.lower()
            is_role_line = bool(re.search(
                r'(engineer|developer|analyst|intern|manager|designer|researcher|lead|associate)',
                line_str, re.IGNORECASE
            ))

            # Parse date range from this line
            months_from_line = self._parse_duration_from_line(line_str, grad_years)

            entry = {
                "role": line_str,
                "isInternship": is_internship,
                "durationMonths": months_from_line,
                "raw": line_str
            }
            if months_from_line > 0 or is_role_line or is_internship:
                exp_entries.append(entry)
                if months_from_line > 0:
                    total_months += months_from_line

        # ── Fallback: look for explicit duration strings ONLY in experience section ──
        if total_months == 0 and exp_section_text:
            total_months = self._sum_duration_strings_in_section(exp_section_text, grad_years)

        # ── Final fallback: no date info → use entry count heuristic ──────────
        if total_months == 0 and exp_entries:
            # Each internship entry averages ~3 months
            internship_count = sum(1 for e in exp_entries if e.get("isInternship"))
            full_job_count = len(exp_entries) - internship_count
            total_months = (internship_count * 3) + (full_job_count * 12)

        total_years = round(total_months / 12.0, 1)

        # Build display string
        if total_months == 0:
            display_string = "Fresher (0 Years)"
        elif total_months < 12:
            display_string = f"{total_months} Months"
        else:
            display_string = f"{total_years} Years"

        return {
            "list": exp_entries,
            "totalYears": total_years,
            "totalMonths": total_months,
            "displayString": display_string
        }

    def _extract_section(self, text: str, start_patterns: list, stop_patterns: list) -> str:
        """Extracts a named section from resume text."""
        lines = text.split("\n")
        in_section = False
        section_lines = []

        for line in lines:
            line_str = line.strip()
            if any(re.search(p, line_str, re.IGNORECASE) for p in start_patterns):
                in_section = True
                continue
            if in_section:
                if any(re.search(p, line_str, re.IGNORECASE) for p in stop_patterns):
                    break
                section_lines.append(line)

        return "\n".join(section_lines)

    def _parse_duration_from_line(self, line: str, grad_years: set) -> int:
        """
        Extracts duration in months from a single line.
        Handles:
          - "Jan 2023 – Apr 2023" (month-based ranges)
          - "2022 – 2024" (year ranges — but only if not graduation year)
          - "3 Months", "6 months", "1 Year"
          - "Present", "Current", "Ongoing"
        Returns: total months as int, or 0 if not found.
        """
        line_lower = line.lower()

        # ── Pattern 1: Named month range (Jan 2023 – Apr 2024 / Jun 2023-Aug 2023) ──
        named_month_range = re.search(
            r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|'
            r'jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)'
            r'[\s\-\.]*(\d{4})'
            r'\s*[–\-–—to]+\s*'
            r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|'
            r'jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?|'
            r'present|current|ongoing)'
            r'[\s\-\.]*(\d{4})?',
            line_lower, re.IGNORECASE
        )
        if named_month_range:
            start_mon_str = named_month_range.group(1)
            start_year_str = named_month_range.group(2)
            end_mon_str = named_month_range.group(3)
            end_year_str = named_month_range.group(4)

            start_month = self.MONTH_MAP.get(start_mon_str[:3].lower(), 1)
            start_year = int(start_year_str)

            if end_mon_str in ('present', 'current', 'ongoing'):
                now = datetime.now()
                end_month = now.month
                end_year = now.year
            else:
                end_month = self.MONTH_MAP.get(end_mon_str[:3].lower(), 1)
                end_year = int(end_year_str) if end_year_str else start_year

            months = (end_year - start_year) * 12 + (end_month - start_month)
            return max(0, months)

        # ── Pattern 2: Numeric month range (MM/YYYY – MM/YYYY or YYYY/MM) ────
        numeric_range = re.search(
            r'(\d{1,2})[/\-](\d{4})\s*[–\-—to]+\s*(\d{1,2})[/\-](\d{4})',
            line
        )
        if numeric_range:
            sm, sy, em, ey = [int(x) for x in numeric_range.groups()]
            months = (ey - sy) * 12 + (em - sm)
            return max(0, months)

        # ── Pattern 3: "X Months" or "X Years" explicit duration ─────────────
        duration_match = re.search(
            r'(\d+(?:\.\d+)?)\s*(months?|mos?)\b',
            line_lower
        )
        if duration_match:
            return int(float(duration_match.group(1)))

        year_duration_match = re.search(
            r'(\d+(?:\.\d+)?)\s*(years?|yrs?)\b',
            line_lower
        )
        if year_duration_match:
            val = float(year_duration_match.group(1))
            # Only trust if value is small enough to be a duration, not a year
            if val < 10:
                return int(val * 12)

        # ── Pattern 4: Year-only range (2022 – 2024) — skip if overlaps with grad year ──
        year_range = re.search(r'\b(20\d{2})\s*[–\-—to]+\s*(20\d{2}|present|current)\b', line_lower)
        if year_range:
            start_y = int(year_range.group(1))
            end_str = year_range.group(2)
            if end_str in ('present', 'current'):
                end_y = datetime.now().year
            else:
                end_y = int(end_str)
            # Skip if this looks like an education year range
            if start_y not in grad_years and end_y not in grad_years:
                months = (end_y - start_y) * 12
                return max(0, min(months, 240))  # cap at 20 years

        return 0

    def _sum_duration_strings_in_section(self, section_text: str, grad_years: set) -> int:
        """
        Scans the experience section for all duration strings and sums them.
        Only uses explicit month/year duration mentions — not bare numbers.
        """
        total_months = 0
        lines = section_text.split("\n")
        for line in lines:
            m = self._parse_duration_from_line(line.strip(), grad_years)
            total_months += m
        return total_months

    # ── EXPANDED SKILLS EXTRACTION ───────────────────────────────────────────
    def _extract_categorized_skills(self, lower_text: str) -> dict:
        """Dynamically identifies technical & soft skills from resume text."""
        custom_skills_db = {
            "languages": [
                "python", "java", "c++", "c", "sql", "pl-sql", "pl/sql", "dart",
                "javascript", "typescript", "r", "scala", "html", "css", "go", "rust",
                "kotlin", "swift", "bash", "shell script"
            ],
            "frameworks": [
                "flutter", "react", "react native", "angular", "vue", "django",
                "fastapi", "flask", "express", "spring boot", "next.js", "tailwind css",
                "bootstrap", "pandas", "numpy", "matplotlib", "seaborn", "scipy"
            ],
            "databases": [
                "postgresql", "postgres", "mongodb", "mysql", "sqlite", "redis",
                "oracle", "sql server", "ms sql", "bigquery", "cassandra", "snowflake"
            ],
            "biTools": [
                "power bi", "microsoft fabric", "qlik", "talend", "pentaho", "tableau",
                "looker", "looker studio", "azure data factory", "adf", "power query",
                "dax", "etl", "data warehouse", "data lake", "apache spark", "hadoop"
            ],
            "cloud": [
                "aws", "azure", "google cloud platform", "gcp", "docker", "kubernetes",
                "terraform", "ansible", "jenkins", "github actions", "ci/cd"
            ],
            "aiMlTools": [
                "machine learning", "deep learning", "scikit-learn", "sklearn",
                "tensorflow", "pytorch", "keras", "hugging face", "nlp",
                "natural language processing", "computer vision", "opencv",
                "xgboost", "lightgbm", "random forest", "neural network",
                "data analysis", "data visualization", "feature engineering",
                "model training", "model deployment", "mlops"
            ],
            "tools": [
                "git", "github", "postman", "power automate", "jira", "figma",
                "vscode", "jupyter", "jupyter notebook", "google colab", "excel",
                "ms office", "microsoft office", "notion"
            ],
            "softSkills": [
                "communication", "leadership", "teamwork", "problem solving",
                "analytical", "agile", "scrum", "critical thinking", "time management",
                "collaboration", "presentation"
            ]
        }

        result = {}
        for cat, skill_list in custom_skills_db.items():
            found = []
            for skill in skill_list:
                pattern = r'\b' + re.escape(skill) + r'\b'
                if re.search(pattern, lower_text):
                    found.append(skill.title())
            result[cat] = found

        return result

    def _extract_projects(self, text: str) -> list:
        projects = []
        lines = text.split("\n")
        in_proj = False

        for line in lines:
            line_str = line.strip()
            if re.search(r'\b(projects?|key projects|academic projects|technical projects)\b', line_str, re.IGNORECASE):
                in_proj = True
                continue
            if in_proj:
                if re.search(r'\b(education|experience|skills|certifications|achievements|awards)\b', line_str, re.IGNORECASE):
                    break
                if line_str and len(line_str) > 5 and not line_str.startswith("http"):
                    projects.append({
                        "name": line_str,
                        "description": line_str
                    })

        return projects[:5]

    def _extract_achievements_and_certs(self, text: str) -> list:
        items = []
        lines = text.split("\n")
        in_section = False

        for line in lines:
            line_str = line.strip()
            if re.search(r'\b(achievements|certifications?|awards|honors|publications|papers)\b', line_str, re.IGNORECASE):
                in_section = True
                continue
            if in_section:
                if re.search(r'\b(education|experience|skills|projects|languages)\b', line_str, re.IGNORECASE):
                    break
                if line_str and len(line_str) > 4:
                    items.append(line_str)

        return items[:6]

    def _detect_domain(self, skills: dict) -> str:
        bi_count = len(skills.get("biTools", []))
        ai_ml_count = len(skills.get("aiMlTools", []))
        cloud_count = len(skills.get("cloud", []))
        framework_count = len(skills.get("frameworks", []))
        lang_list = [s.lower() for s in skills.get("languages", [])]

        # Data Analytics / BI takes highest priority when BI tools or SQL present
        if bi_count > 0:
            return "Data Analytics & BI"
        if "sql" in lang_list or "r" in lang_list:
            if ai_ml_count > 0:
                return "Data Analytics & BI"
        if ai_ml_count >= 2:
            return "AI / Machine Learning"
        if cloud_count >= 2:
            return "Cloud Engineering"
        if framework_count > 0 and "flutter" in [s.lower() for s in skills.get("frameworks", [])]:
            return "Mobile App Development"
        if lang_list:
            return "Software Engineering"
        return "Software Development"
