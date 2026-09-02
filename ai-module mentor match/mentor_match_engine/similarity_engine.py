"""
Mentor Match Engine — Similarity Engine
=========================================
Calculates Cosine Similarity between Student and Mentor SBERT embeddings.

Mathematics & Principles:
  Cosine similarity measures the cosine of the angle between two multi-dimensional
  vectors in SBERT embedding space (384 dimensions for all-MiniLM-L6-v2).

  Formula:
      similarity = (v_student · v_mentor) / (||v_student|| * ||v_mentor||)

  For L2-normalized vectors (unit length, ||v|| = 1.0):
      similarity = v_student · v_mentor (dot product)

Score Range vs Presentation Match Percentage:
  - Raw Cosine Similarity : [-1.0, 1.0] (For text embeddings, typically [0.0, 1.0])
  - User Match Percentage : [0.0%, 100.0%] (Formally derived: round(raw_score * 100, 1))

Decoupled & Pure:
  Uses NumPy for high-performance vectorized linear algebra.
"""

import numpy as np
from typing import List, Tuple, Union


class SimilarityEngine:
    """High-performance Cosine Similarity engine for dense profile vectors."""

    @staticmethod
    def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
        """Calculate raw Cosine Similarity between two 1D embedding vectors.

        Args:
            vec_a: 1D numpy array of shape (dim,).
            vec_b: 1D numpy array of shape (dim,).

        Returns:
            Cosine similarity score as float in range [-1.0, 1.0].

        Raises:
            ValueError: If inputs are empty or have mismatched dimensions.
        """
        if vec_a is None or vec_b is None:
            raise ValueError("Input vectors cannot be None.")

        arr_a = np.asarray(vec_a, dtype=np.float32).ravel()
        arr_b = np.asarray(vec_b, dtype=np.float32).ravel()

        if arr_a.size == 0 or arr_b.size == 0:
            raise ValueError("Vector arrays cannot be empty.")

        if arr_a.shape != arr_b.shape:
            raise ValueError(
                f"Embedding dimension mismatch: vec_a shape {arr_a.shape} vs vec_b shape {arr_b.shape}."
            )

        norm_a = np.linalg.norm(arr_a)
        norm_b = np.linalg.norm(arr_b)

        if norm_a == 0.0 or norm_b == 0.0:
            return 0.0

        sim = float(np.dot(arr_a, arr_b) / (norm_a * norm_b))
        # Clip numerical precision artifacts outside [-1.0, 1.0]
        return float(np.clip(sim, -1.0, 1.0))

    @staticmethod
    def batch_cosine_similarity(
        student_embedding: np.ndarray,
        mentor_embeddings: np.ndarray,
    ) -> np.ndarray:
        """Calculate Cosine Similarity between a single student vector and a matrix of mentor vectors.

        Args:
            student_embedding: 1D array of shape (dim,).
            mentor_embeddings: 2D array of shape (num_mentors, dim) or 1D if single mentor.

        Returns:
            1D float32 numpy array of similarity scores of shape (num_mentors,).

        Raises:
            ValueError: If input dimensions are invalid or mismatched.
        """
        if student_embedding is None or mentor_embeddings is None:
            raise ValueError("Embeddings cannot be None.")

        stu_arr = np.asarray(student_embedding, dtype=np.float32).ravel()
        men_arr = np.asarray(mentor_embeddings, dtype=np.float32)

        if stu_arr.size == 0 or men_arr.size == 0:
            raise ValueError("Embedding arrays cannot be empty.")

        if men_arr.ndim == 1:
            men_arr = men_arr.reshape(1, -1)
        elif men_arr.ndim != 2:
            raise ValueError(f"Mentor embeddings matrix must be 1D or 2D, got {men_arr.ndim}D.")

        if stu_arr.shape[0] != men_arr.shape[1]:
            raise ValueError(
                f"Dimension mismatch: student vector dimension ({stu_arr.shape[0]}) "
                f"does not match mentor matrix dimension ({men_arr.shape[1]})."
            )

        stu_norm = np.linalg.norm(stu_arr)
        if stu_norm == 0.0:
            return np.zeros(men_arr.shape[0], dtype=np.float32)

        stu_unit = stu_arr / stu_norm

        men_norms = np.linalg.norm(men_arr, axis=1, keepdims=True)
        men_norms = np.where(men_norms == 0.0, 1.0, men_norms)
        men_unit = men_arr / men_norms

        similarities = np.dot(men_unit, stu_unit)
        similarities = np.clip(similarities, -1.0, 1.0)
        return similarities.astype(np.float32)

    @staticmethod
    def similarity_to_percentage(similarity_score: float) -> float:
        """Convert raw cosine similarity score [-1.0, 1.0] into a user-facing match percentage [0.0, 100.0].

        Args:
            similarity_score: Cosine similarity score (e.g. 0.842).

        Returns:
            Rounded match percentage float (e.g. 84.2).
        """
        clamped = max(-1.0, min(1.0, float(similarity_score)))
        # For text embeddings, negative similarity is non-matching (0%)
        if clamped <= 0.0:
            return 0.0
        return round(clamped * 100.0, 1)

    @classmethod
    def rank_by_similarity(
        cls,
        similarities: np.ndarray,
        top_k: int = 5,
    ) -> List[Tuple[int, float]]:
        """Rank mentor indices by similarity score in descending order.

        Args:
            similarities: Array of similarity scores.
            top_k: Number of top indices to return (must be > 0).

        Returns:
            List of (mentor_index, similarity_score) tuples, sorted highest to lowest.
        """
        if top_k <= 0:
            raise ValueError(f"top_k must be greater than 0, got {top_k}.")

        if similarities is None or len(similarities) == 0:
            return []

        sims = np.asarray(similarities, dtype=np.float32).ravel()
        sorted_indices = np.argsort(sims)[::-1]
        top_indices = sorted_indices[:min(top_k, len(sims))]

        return [(int(idx), float(sims[idx])) for idx in top_indices]
