import os
import pickle
import numpy as np
from typing import Dict, List, Optional
from app.core.config import settings

class EmbeddingService:
    def __init__(self):
        self.model_name = settings.EMBEDDING_MODEL
        self._model = None
        self._cache_path = settings.EMBEDDINGS_CACHE_PATH
        self._cached_embeddings: Dict[str, np.ndarray] = {}

    def _lazy_load_model(self):
        if self._model is not None:
            return
        
        try:
            from sentence_transformers import SentenceTransformer
            self._model = SentenceTransformer(self.model_name)
        except ImportError:
            print("Warning: 'sentence-transformers' not installed. Running in Mock/Fallback embedding mode.")
            self._model = "MOCK"
        except Exception as e:
            print(f"Warning: Failed to load sentence transformer model: {e}. Running in Fallback mode.")
            self._model = "MOCK"

    def get_embedding(self, text: str) -> np.ndarray:
        self._lazy_load_model()
        
        if not text:
            return np.zeros(384)
            
        if self._model is None or self._model == "MOCK":
            # Deterministic pseudo-random embedding based on string hash for testing consistency
            np.random.seed(abs(hash(text)) % (2**32))
            return np.random.randn(384)
            
        try:
            embedding = self._model.encode(text, convert_to_numpy=True)
            return embedding
        except Exception as e:
            print(f"Error generating embedding: {e}. Falling back to mock vector.")
            np.random.seed(abs(hash(text)) % (2**32))
            return np.random.randn(384)

    def get_embeddings(self, texts: List[str]) -> List[np.ndarray]:
        return [self.get_embedding(text) for text in texts]

    def load_cached_career_embeddings(self) -> Dict[str, np.ndarray]:
        if self._cached_embeddings:
            return self._cached_embeddings
            
        if os.path.exists(self._cache_path):
            try:
                with open(self._cache_path, 'rb') as f:
                    self._cached_embeddings = pickle.load(f)
                    return self._cached_embeddings
            except Exception as e:
                print(f"Warning: Failed to load cached career embeddings: {e}")
                
        return {}

    def save_career_embeddings(self, embeddings: Dict[str, np.ndarray]):
        self._cached_embeddings = embeddings
        os.makedirs(os.path.dirname(self._cache_path), exist_ok=True)
        try:
            with open(self._cache_path, 'wb') as f:
                pickle.dump(embeddings, f)
        except Exception as e:
            print(f"Error saving career embeddings cache: {e}")

# Singleton instance
embedding_service = EmbeddingService()
