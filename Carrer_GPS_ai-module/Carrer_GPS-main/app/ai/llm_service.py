import json
import os
import abc
import re
from typing import Optional, Dict, Any, Type, List
from pydantic import BaseModel
from app.core.config import settings
from app.models.result import Personalization
from app.ai.prompts import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE

class LLMService(abc.ABC):
    @abc.abstractmethod
    def generate(self, system_prompt: str, user_prompt: str) -> str:
        """Sends prompts to the LLM and returns the raw string response."""
        pass

    @abc.abstractmethod
    def generate_personalization(self, prompt_kwargs: dict) -> Personalization:
        """Generates a structured Personalization object directly from deterministic metrics."""
        pass

class GeminiLLMService(LLMService):
    def __init__(self):
        self.api_key = settings.LLM_API_KEY or os.environ.get("LLM_API_KEY")
        self.model_name = settings.LLM_MODEL
        self._initialized = False
        
    def _initialize(self):
        if self._initialized:
            return
        if not self.api_key:
            raise ValueError("Gemini API key is not configured. Set LLM_API_KEY in your environment or .env file.")
        
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self._genai = genai
            self._initialized = True
        except ImportError:
            raise ImportError("Failed to import 'google-generativeai'. Please install it using pip.")

    def generate(self, system_prompt: str, user_prompt: str) -> str:
        self._initialize()
        
        try:
            model = self._genai.GenerativeModel(
                model_name=self.model_name,
                system_instruction=system_prompt
            )
            
            # Request JSON output structure if supported
            generation_config = {
                "response_mime_type": "application/json"
            }
            
            response = model.generate_content(
                user_prompt,
                generation_config=generation_config
            )
            return response.text
        except Exception as e:
            print(f"Error calling Gemini API: {e}")
            raise e

    def generate_personalization(self, prompt_kwargs: dict) -> Personalization:
        self._initialize()
        
        user_prompt = USER_PROMPT_TEMPLATE.format(**prompt_kwargs)
        
        try:
            model = self._genai.GenerativeModel(
                model_name=self.model_name,
                system_instruction=SYSTEM_PROMPT
            )
            
            # Use structured output for strictly enforcing schema
            generation_config = self._genai.GenerationConfig(
                response_mime_type="application/json",
                response_schema=Personalization
            )
            
            response = model.generate_content(
                user_prompt,
                generation_config=generation_config
            )
            
            # The response.text is guaranteed to be JSON matching the schema
            import json
            return Personalization(**json.loads(response.text))
        except Exception as e:
            print(f"Error calling Gemini API with response_schema: {e}")
            raise e

class MockLLMService(LLMService):
    def generate(self, system_prompt: str, user_prompt: str) -> str:
        # Fallback string mock
        return "{}"

    def generate_personalization(self, prompt_kwargs: dict) -> Personalization:
        target_career = prompt_kwargs.get("target_career", "Target Career")
        missing_skills = prompt_kwargs.get("missing_skills", "[]")
        strengths = prompt_kwargs.get("strong_skills", "[]")
        
        return Personalization(
            summary=f"Mock synthesis for {target_career}. Strong foundations in {strengths[:20]}.",
            strengths=["Mocked Strength 1", "Mocked Strength 2"],
            priority_gaps=["Mocked Gap 1"],
            recommendations=["Mocked Project or Learning"],
            roadmap_explanation="Mocked roadmap explanation",
            next_best_action="Mocked next best action.",
            risks=["Mock risk 1"]
        )

# Factory/service resolver
def get_llm_service() -> LLMService:
    provider = settings.LLM_PROVIDER.lower().strip()
    api_key = settings.LLM_API_KEY or os.environ.get("LLM_API_KEY")
    
    if provider == "gemini" and api_key:
        return GeminiLLMService()
    else:
        if provider == "gemini" and not api_key:
            print("Warning: Gemini LLM service requested but LLM_API_KEY is not set. Falling back to MockLLMService.")
        return MockLLMService()
