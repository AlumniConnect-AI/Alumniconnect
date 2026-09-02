"""
Mentor Match Engine — SBERT Profile Encoder
=============================================
Converts student and mentor profile structures into dense numerical semantic
embedding vectors using Sentence-BERT (SBERT).

Model Choice:
  Default: 'sentence-transformers/all-MiniLM-L6-v2'
  - 384-dimensional dense embedding vectors
  - Fast, lightweight (~80MB), optimized for CPU inference
  - High performance on semantic textual similarity (STS) benchmarks

Features:
  - Lazy loading: SBERT model is loaded on first encoding request (not at import time)
  - Structured text builder: converts StudentProfile and MentorProfile into semantically rich text
  - Normalization: embeddings are L2-normalized by default (unit length for cosine similarity)
  - Batching: efficient matrix encoding for collections of mentor profiles
"""

import logging
from typing import List, Union, Optional, Any
import numpy as np

from .models import StudentProfile, MentorProfile

logger = logging.getLogger(__name__)

# Default lightweight SBERT model
DEFAULT_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"


class ProfileEncoder:
    """Encodes StudentProfile and MentorProfile objects into dense vector embeddings.

    Uses Sentence-BERT (SBERT) to map text representations into a 384-dimensional
    vector space where semantically similar profiles are close together.
    """

    def __init__(
        self,
        model_name: str = DEFAULT_MODEL_NAME,
        device: Optional[str] = None,
    ):
        """Initialize the ProfileEncoder.

        Args:
            model_name: HuggingFace/SBERT model identifier.
                        Default: 'sentence-transformers/all-MiniLM-L6-v2'.
            device: Computing device ('cpu', 'cuda', etc.). If None, SBERT auto-selects.
        """
        self.model_name = model_name
        self.device = device
        self._model = None  # Lazily loaded SentenceTransformer instance
        self._embedding_dim: Optional[int] = None

    def _get_model(self):
        """Lazy-load the SBERT SentenceTransformer model on first use."""
        if self._model is None:
            try:
                from sentence_transformers import SentenceTransformer
                logger.info(f"Loading SBERT model '{self.model_name}'...")
                self._model = SentenceTransformer(
                    self.model_name,
                    device=self.device
                )
                self._embedding_dim = self._model.get_sentence_embedding_dimension()
                logger.info(
                    f"SBERT model '{self.model_name}' loaded successfully "
                    f"(embedding dimension: {self._embedding_dim})."
                )
            except Exception as err:
                raise RuntimeError(
                    f"Failed to load SBERT model '{self.model_name}': {err}"
                ) from err
        return self._model

    def is_model_loaded(self) -> bool:
        """Check if the SBERT model is currently loaded in memory."""
        return self._model is not None

    def get_embedding_dimension(self) -> int:
        """Returns the dimensionality of the generated embedding vectors (e.g. 384)."""
        if self._embedding_dim is not None:
            return self._embedding_dim
        model = self._get_model()
        return self._embedding_dim or model.get_sentence_embedding_dimension()

    # ── Profile Text Conversion ───────────────────────────────────────────────

    @staticmethod
    def build_profile_text(profile: Union[StudentProfile, MentorProfile, dict, Any]) -> str:
        """Converts a student or mentor profile object into a structured text representation.

        Preserves semantic information (skills, interests, goals, domain, bio, experience)
        in a clean format optimized for transformer embedding models.

        Args:
            profile: A StudentProfile, MentorProfile, dict, or object with to_text().

        Returns:
            Structured text string.

        Raises:
            ValueError: If profile is None or invalid.
        """
        if profile is None:
            raise ValueError("Cannot convert None profile to text.")

        # Handle StudentProfile explicitly
        if isinstance(profile, StudentProfile):
            lines = []
            if profile.name:
                lines.append(f"Student Name: {profile.name}")
            if profile.education:
                lines.append(f"Education: {profile.education}")
            if profile.department:
                lines.append(f"Department: {profile.department}")
            if profile.skills:
                lines.append(f"Skills: {', '.join(profile.skills)}")
            if profile.interests:
                lines.append(f"Interests: {', '.join(profile.interests)}")
            if profile.career_goals:
                lines.append(f"Career Goal: {profile.career_goals}")
            exp_str = (
                f"{profile.experience_years} years"
                if profile.experience_years > 0
                else "Fresher"
            )
            lines.append(f"Experience: {exp_str}")
            if profile.bio:
                lines.append(f"Bio: {profile.bio}")
            return "\n".join(lines).strip()

        # Handle MentorProfile explicitly
        if isinstance(profile, MentorProfile):
            lines = []
            if profile.name:
                lines.append(f"Mentor Name: {profile.name}")
            if profile.current_role:
                lines.append(f"Current Role: {profile.current_role}")
            if profile.company:
                lines.append(f"Company: {profile.company}")
            if profile.career_domain:
                lines.append(f"Career Domain: {profile.career_domain}")
            if profile.education:
                lines.append(f"Education: {profile.education}")
            if profile.department:
                lines.append(f"Department: {profile.department}")
            if profile.skills:
                lines.append(f"Skills: {', '.join(profile.skills)}")
            if profile.interests:
                lines.append(f"Interests: {', '.join(profile.interests)}")
            if profile.experience_years > 0:
                lines.append(f"Experience: {profile.experience_years} years")
            if profile.bio:
                lines.append(f"Bio: {profile.bio}")
            return "\n".join(lines).strip()

        # If object has custom to_text() implementation
        if hasattr(profile, "to_text") and callable(getattr(profile, "to_text")):
            custom_text = profile.to_text()
            if custom_text and custom_text.strip():
                return custom_text.strip()

        # Handle Dictionary input
        if isinstance(profile, dict):
            lines = []
            for key, val in profile.items():
                if val:
                    if isinstance(val, list):
                        lines.append(f"{key.replace('_', ' ').title()}: {', '.join(map(str, val))}")
                    else:
                        lines.append(f"{key.replace('_', ' ').title()}: {val}")
            return "\n".join(lines).strip()

        # Fallback string representation
        text_repr = str(profile).strip()
        if not text_repr:
            raise ValueError(f"Could not extract meaningful text from profile object: {profile}")
        return text_repr

    # ── Encoding API ──────────────────────────────────────────────────────────

    def encode_text(
        self,
        text: str,
        normalize_embeddings: bool = True,
    ) -> np.ndarray:
        """Encode a single text string into a 1D embedding vector.

        Args:
            text: Raw text to encode.
            normalize_embeddings: If True, L2-normalizes the vector to unit length.

        Returns:
            1D numpy float32 array of shape (embedding_dim,).

        Raises:
            ValueError: If text is empty or whitespace-only.
        """
        if not text or not text.strip():
            raise ValueError("Cannot encode empty or whitespace-only text.")

        model = self._get_model()
        embedding = model.encode(
            text.strip(),
            convert_to_numpy=True,
            normalize_embeddings=normalize_embeddings,
            show_progress_bar=False,
        )
        return np.asarray(embedding, dtype=np.float32)

    def encode_texts(
        self,
        texts: List[str],
        normalize_embeddings: bool = True,
        batch_size: int = 32,
        show_progress_bar: bool = False,
    ) -> np.ndarray:
        """Encode a batch of text strings into a 2D embedding matrix.

        Args:
            texts: List of text strings.
            normalize_embeddings: If True, L2-normalizes vectors to unit length.
            batch_size: Number of texts per inference batch.
            show_progress_bar: Whether to display a progress bar.

        Returns:
            2D numpy float32 array of shape (num_texts, embedding_dim).

        Raises:
            ValueError: If texts list is empty or contains empty strings.
        """
        if not texts:
            raise ValueError("Cannot encode empty list of texts.")

        cleaned_texts = []
        for i, t in enumerate(texts):
            if not t or not str(t).strip():
                raise ValueError(f"Text at index {i} is empty or invalid.")
            cleaned_texts.append(str(t).strip())

        model = self._get_model()
        embeddings = model.encode(
            cleaned_texts,
            convert_to_numpy=True,
            normalize_embeddings=normalize_embeddings,
            batch_size=batch_size,
            show_progress_bar=show_progress_bar,
        )
        return np.asarray(embeddings, dtype=np.float32)

    def encode_student_profile(
        self,
        student_profile: StudentProfile,
        normalize_embeddings: bool = True,
    ) -> np.ndarray:
        """Encode a StudentProfile into a 1D embedding vector.

        Args:
            student_profile: StudentProfile dataclass instance.
            normalize_embeddings: Normalize to unit length (default True).

        Returns:
            1D numpy float32 array of shape (embedding_dim,).
        """
        text = self.build_profile_text(student_profile)
        return self.encode_text(text, normalize_embeddings=normalize_embeddings)

    def encode_mentor_profile(
        self,
        mentor_profile: MentorProfile,
        normalize_embeddings: bool = True,
    ) -> np.ndarray:
        """Encode a MentorProfile into a 1D embedding vector.

        Args:
            mentor_profile: MentorProfile dataclass instance.
            normalize_embeddings: Normalize to unit length (default True).

        Returns:
            1D numpy float32 array of shape (embedding_dim,).
        """
        text = self.build_profile_text(mentor_profile)
        return self.encode_text(text, normalize_embeddings=normalize_embeddings)

    def encode_profiles(
        self,
        profiles: List[Union[StudentProfile, MentorProfile, dict, Any]],
        normalize_embeddings: bool = True,
        batch_size: int = 32,
        show_progress_bar: bool = False,
    ) -> np.ndarray:
        """Batch encode a list of student or mentor profiles into an embedding matrix.

        Args:
            profiles: List of StudentProfile or MentorProfile objects.
            normalize_embeddings: Normalize to unit length (default True).
            batch_size: Number of profiles per batch.
            show_progress_bar: Display progress bar.

        Returns:
            2D numpy float32 array of shape (num_profiles, embedding_dim).
        """
        if not profiles:
            raise ValueError("Cannot encode empty profiles list.")

        texts = [self.build_profile_text(p) for p in profiles]
        return self.encode_texts(
            texts,
            normalize_embeddings=normalize_embeddings,
            batch_size=batch_size,
            show_progress_bar=show_progress_bar,
        )

    # ── Backward Compatibility Aliases ───────────────────────────────────────

    def encode_profile(
        self,
        profile: Union[StudentProfile, MentorProfile, dict, Any],
        normalize_embeddings: bool = True,
    ) -> np.ndarray:
        """Alias for encoding a single profile (student or mentor)."""
        text = self.build_profile_text(profile)
        return self.encode_text(text, normalize_embeddings=normalize_embeddings)

    def encode_batch(
        self,
        profiles: List[Union[StudentProfile, MentorProfile, dict, Any]],
        normalize_embeddings: bool = True,
        batch_size: int = 32,
    ) -> np.ndarray:
        """Alias for batch encoding profiles."""
        return self.encode_profiles(
            profiles,
            normalize_embeddings=normalize_embeddings,
            batch_size=batch_size,
        )

