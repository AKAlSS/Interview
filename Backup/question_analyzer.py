import spacy
import re
from transformers import pipeline

class QuestionAnalyzer:
    def __init__(self):
        # Load NLP model
        self.nlp = spacy.load("en_core_web_lg")
        
        # Technical keywords for UX development
        self.ux_keywords = ["accessibility", "ARIA", "usability", "UI", "user flow", 
                           "wireframe", "prototype", "JavaScript", "React", "Vue", 
                           "CSS", "HTML", "responsive design", "user research"]
        
        # Code detection patterns
        self.code_patterns = [
            r"write (a|an) (function|algorithm|program|code)",
            r"implement (a|an) (function|method|component)",
            r"how would you code",
            r"create (a|an) (component|module|class)"
        ]
        
        # Zero-shot classifier for question types
        self.classifier = pipeline("zero-shot-classification")
        
    def analyze(self, transcript):
        doc = self.nlp(transcript)
        
        # Check if it's asking for code
        is_coding_question = any(re.search(pattern, transcript.lower()) for pattern in self.code_patterns)
        
        # Technical question detection
        technical_keywords_found = [keyword for keyword in self.ux_keywords 
                                   if keyword.lower() in transcript.lower()]
        
        # Classify question type
        question_type = self.classifier(
            transcript,
            candidate_labels=["technical explanation", "coding exercise", "personal experience", 
                             "behavioral", "opinion", "system design"],
        )
        
        # Extract key entities
        entities = [ent.text for ent in doc.ents]
        
        return {
            "is_technical": len(technical_keywords_found) > 0 or is_coding_question,
            "is_coding_question": is_coding_question,
            "question_type": question_type["labels"][0],
            "confidence": question_type["scores"][0],
            "keywords_detected": technical_keywords_found,
            "entities": entities,
            "transcript": transcript
        } 