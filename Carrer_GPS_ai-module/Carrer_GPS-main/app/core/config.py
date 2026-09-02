import os
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

# Base directory of the project
BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    # Application Config
    APP_NAME: str = "Career GPS Engine"
    DEBUG: bool = False

    # LLM Settings
    # Supports: "gemini", "mock"
    LLM_PROVIDER: str = "gemini"
    LLM_API_KEY: Optional[str] = None
    LLM_MODEL: str = "gemini-3.5-flash"

    # Embedding Settings
    EMBEDDING_MODEL: str = "all-MiniLM-L6-v2"
    EMBEDDINGS_CACHE_PATH: str = str(BASE_DIR / "data" / "career_embeddings.pkl")

    # Data Path Settings
    DATA_DIR: str = str(BASE_DIR / "data")

    # Configuration file settings
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
