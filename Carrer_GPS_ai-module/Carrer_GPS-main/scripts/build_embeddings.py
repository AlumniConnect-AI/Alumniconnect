import sys
from pathlib import Path

# Add project root to sys.path so we can import app modules
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from app.knowledge.career_database import career_db
from app.ai.embedding_service import embedding_service

def main():
    print("Initializing career embeddings builder...")
    
    careers = career_db.list_careers()
    if not careers:
        print("Error: No careers found in the career database. Make sure data/careers.json exists.")
        sys.exit(1)
        
    print(f"Generating embeddings for {len(careers)} careers...")
    career_embeddings = {}
    
    for career in careers:
        text_to_embed = f"{career.title}: {career.description}"
        print(f" - Generating embedding for: {career.title}")
        vector = embedding_service.get_embedding(text_to_embed)
        career_embeddings[career.id] = vector
        
    print("Saving career embeddings cache to disk...")
    embedding_service.save_career_embeddings(career_embeddings)
    print("Career embeddings successfully compiled and cached!")

if __name__ == "__main__":
    main()
