import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class SemanticSimilarityEngine:
    """Computes NLP semantic similarity between candidate profile and job description."""

    def __init__(self):
        self.vectorizer = TfidfVectorizer(stop_words='english')

    def calculate_similarity(self, profile_text: str, jd_text: str) -> float:
        """Calculates TF-IDF cosine similarity score between 0.0 and 1.0."""
        if not profile_text or not jd_text:
            return 0.0

        try:
            matrix = self.vectorizer.fit_transform([profile_text, jd_text])
            sim = cosine_similarity(matrix[0:1], matrix[1:2])[0][0]
            return round(float(sim), 4)
        except Exception:
            return 0.0

    @staticmethod
    def get_skill_overlap(candidate_skills: list, jd_skills: list) -> dict:
        """Calculates matching, missing, and extra skills between candidate and job description."""
        set_cand = set([str(s).lower().strip() for s in candidate_skills])
        set_jd = set([str(s).lower().strip() for s in jd_skills])

        matched = sorted(list(set_cand.intersection(set_jd)))
        missing = sorted(list(set_jd.difference(set_cand)))
        extra = sorted(list(set_cand.difference(set_jd)))

        return {
            "matched": matched,
            "missing": missing,
            "extra": extra
        }
