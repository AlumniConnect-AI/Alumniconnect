import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class SemanticMatcher:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(stop_words='english')

    def calculate_similarity(self, profile_text: str, jd_text: str) -> float:
        """Calculates semantic similarity between candidate profile and job description using TF-IDF and cosine similarity."""
        try:
            # Combine texts to fit the vectorizer vocab
            tfidf_matrix = self.vectorizer.fit_transform([profile_text, jd_text])
            
            # Compute cosine similarity
            similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])
            
            # Extract float value
            score = float(similarity[0][0])
            return round(score, 4)
        except Exception as e:
            # Safe fallback if input texts are empty/corrupt
            return 0.0

    @staticmethod
    def get_token_overlap(list_a: list, list_b: list) -> dict:
        """Helper to find matching, missing, and extra items between two lists (e.g. skills)."""
        set_a = set([str(x).lower().strip() for x in list_a])
        set_b = set([str(x).lower().strip() for x in list_b])
        
        matched_items = list(set_a.intersection(set_b))
        missing_items = list(set_b.difference(set_a))
        extra_items = list(set_a.difference(set_b))
        
        return {
            "matched": sorted(matched_items),
            "missing": sorted(missing_items),
            "extra": sorted(extra_items)
        }
