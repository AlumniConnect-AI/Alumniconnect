import json
import re
from typing import Optional, List, Dict, Any
from app.models.result import Personalization
from app.ai.llm_service import LLMService

def clean_json_string(text: str) -> str:
    # Removes markdown code block wraps (e.g. ```json ... ```)
    text = text.strip()
    # Remove markdown code block backticks
    text = re.sub(r"^```(?:json)?\s*\n?", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\n?\s*```$", "", text)
    return text.strip()

class OutputParser:
    def __init__(self, llm_service: Optional[LLMService] = None):
        self.llm_service = llm_service

    def parse_and_validate(self, raw_response: str, user_prompt: Optional[str] = None) -> Personalization:
        cleaned = clean_json_string(raw_response)
        
        try:
            parsed_data = json.loads(cleaned)
            return Personalization(**parsed_data)
        except Exception as first_error:
            print(f"Warning: JSON parsing or validation failed on initial LLM response: {first_error}")
            
            # Attempt to fix using Gemini retry, if service and prompt are available
            if self.llm_service and user_prompt:
                try:
                    print("Attempting LLM correction retry...")
                    correction_system_prompt = (
                        "You are a strict JSON fixer. You received invalid JSON output from an LLM. "
                        "Your job is to fix it so that it is valid, parseable JSON and conforms exactly to the target schema. "
                        "Return the corrected JSON object ONLY. No explanation, no backticks."
                    )
                    correction_user_prompt = (
                        f"Target Schema:\n"
                        f"{{\n"
                        f"  'summary': 'string',\n"
                        f"  'strengths': ['string'],\n"
                        f"  'priority_gaps': ['string'],\n"
                        f"  'recommendations': ['string'],\n"
                        f"  'roadmap_explanation': 'string',\n"
                        f"  'next_best_action': 'string',\n"
                        f"  'risks': ['string']\n"
                        f"}}\n\n"
                        f"Error received: {str(first_error)}\n\n"
                        f"Raw LLM output to fix:\n{raw_response}"
                    )
                    
                    retry_response = self.llm_service.generate(
                        system_prompt=correction_system_prompt,
                        user_prompt=correction_user_prompt
                    )
                    
                    retry_cleaned = clean_json_string(retry_response)
                    parsed_retry = json.loads(retry_cleaned)
                    return Personalization(**parsed_retry)
                except Exception as retry_error:
                    print(f"Warning: LLM correction retry failed: {retry_error}")
            
            # If retry failed or wasn't possible, apply deterministic fallback
            return self.get_deterministic_fallback(user_prompt)

    def get_deterministic_fallback(self, user_prompt: Optional[str]) -> Personalization:
        print("Using deterministic fallback LLM parser response.")
        
        # Parse basic fields from the prompt if possible
        target_career = "Target Career"
        if user_prompt:
            match = re.search(r"Target Career:\s*(.*)", user_prompt)
            if match:
                target_career = match.group(1).strip()
                
        return Personalization(
            summary=f"Analysis completed for the target career path: {target_career}. We have outlined key steps to bridge your current qualifications to the required levels.",
            strengths=["Core technical foundations"],
            priority_gaps=["Primary required skill gaps listed in the roadmap"],
            recommendations=[f"Review the step-by-step phases of the {target_career} roadmap and begin learning prerequisites first."],
            roadmap_explanation="Pacing is ordered according to skill dependencies to ensure you learn fundamentals before advanced integrations.",
            next_best_action="Begin the first learning task under Phase 1 of your roadmap.",
            risks=["Transition speed depends on the hours committed per week to closing gaps."]
        )
