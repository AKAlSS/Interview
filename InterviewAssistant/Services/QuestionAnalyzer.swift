import Foundation
import NaturalLanguage

class QuestionAnalyzer {
    private let technicalKeywords: Set<String>
    private let codingKeywords: Set<String>
    private var context: [String] = []
    
    init() {
        // Technical keywords for UX development
        technicalKeywords = Set([
            "css", "html", "javascript", "typescript", "react", "vue", "angular", 
            "responsive", "accessibility", "a11y", "wcag", "aria", "dom", "api",
            "component", "layout", "flexbox", "grid", "framework", "library",
            "frontend", "backend", "fullstack", "mvc", "design pattern", "algorithm"
        ])
        
        // Keywords that indicate a coding request
        codingKeywords = Set([
            "write", "code", "implement", "function", "method", "component", 
            "create", "build", "develop", "program", "script", "class",
            "algorithm", "solution"
        ])
    }
    
    func analyze(_ transcript: String) -> QuestionAnalysis {
        let lowercased = transcript.lowercased()
        
        // Check if it's a question
        let isQuestion = lowercased.contains("?") || 
                        lowercased.starts(with: "how") ||
                        lowercased.starts(with: "what") ||
                        lowercased.starts(with: "why") ||
                        lowercased.starts(with: "can you") ||
                        lowercased.starts(with: "could you")
        
        if !isQuestion {
            return QuestionAnalysis(is_technical: false, is_coding_question: false, 
                                   is_follow_up: false, question_type: "not_question",
                                   keywords_detected: [], context: "", transcript: transcript)
        }
        
        // Check for technical keywords
        let detectedTechKeywords = technicalKeywords.filter { lowercased.contains($0) }
        let isTechnical = !detectedTechKeywords.isEmpty
        
        // Check for coding keywords
        let detectedCodingKeywords = codingKeywords.filter { lowercased.contains($0) }
        let isCodingQuestion = !detectedCodingKeywords.isEmpty
        
        // Add to context and check if it's a follow-up
        updateContext(transcript)
        let isFollowUp = isFollowUpQuestion(lowercased)
        
        // Determine question type
        let questionType = determineQuestionType(lowercased)
        
        return QuestionAnalysis(
            is_technical: isTechnical,
            is_coding_question: isCodingQuestion,
            is_follow_up: isFollowUp,
            question_type: questionType,
            keywords_detected: Array(detectedTechKeywords),
            context: context.suffix(3).joined(separator: " "),
            transcript: transcript
        )
    }
    
    private func determineQuestionType(_ question: String) -> String {
        // Using NLTagger for basic categorization
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = question
        
        // Count occurrences of different parts of speech
        var counts: [String: Int] = [:]
        
        tagger.enumerateTags(in: question.startIndex..<question.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                counts[tag.rawValue, default: 0] += 1
            }
            return true
        }
        
        // Simple categorization based on keywords
        if question.contains("algorithm") || question.contains("complexity") {
            return "algorithm"
        } else if question.contains("data structure") || question.contains("array") || question.contains("linked list") {
            return "data_structure"
        } else if question.contains("design") && (question.contains("system") || question.contains("architecture")) {
            return "system_design"
        } else if question.contains("css") || question.contains("html") || question.contains("ui") {
            return "frontend"
        } else {
            return "general_technical"
        }
    }
    
    private func isFollowUpQuestion(_ question: String) -> Bool {
        // Check for follow-up indicators
        let followUpIndicators = ["how would you", "what about", "can you explain", 
                                 "why did you", "what if", "could you elaborate"]
        
        return followUpIndicators.contains { question.contains($0) }
    }
    
    private func updateContext(_ question: String) {
        context.append(question)
        if context.count > 5 {
            context.removeFirst()
        }
    }
} 