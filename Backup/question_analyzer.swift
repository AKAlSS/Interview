import Foundation
import NaturalLanguage

class QuestionAnalyzer {
    private var technicalKeywords: Set<String>
    private var codingKeywords: Set<String>
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
    
    func analyze(_ question: String) -> QuestionAnalysis {
        let lowercasedQuestion = question.lowercased()
        
        // Check if technical
        let technicalTerms = technicalKeywords.filter { lowercasedQuestion.contains($0) }
        let isTechnical = !technicalTerms.isEmpty
        
        // Check if coding question
        let codingTerms = codingKeywords.filter { lowercasedQuestion.contains($0) }
        let isCodingQuestion = !codingTerms.isEmpty
        
        // Determine if it's a follow-up question
        let isFollowUp = isFollowUpQuestion(lowercasedQuestion)
        
        // Add to context
        updateContext(question)
        
        // Determine category (using NLP)
        let category = determineCategory(lowercasedQuestion)
        
        return QuestionAnalysis(
            is_technical: isTechnical,
            is_coding_question: isCodingQuestion,
            is_follow_up: isFollowUp,
            question_type: category,
            keywords_detected: Array(technicalTerms),
            context: context.suffix(3).joined(separator: " "),
            transcript: question
        )
    }
    
    private func determineCategory(_ question: String) -> String {
        // Using NLTagger for basic categorization
        // In a real implementation, we'd use a more sophisticated model
        
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

struct QuestionAnalysis {
    let is_technical: Bool
    let is_coding_question: Bool
    let is_follow_up: Bool
    let question_type: String
    let keywords_detected: [String]
    let context: String
    let transcript: String
    
    var confidence: Double {
        // Simple confidence scoring based on keyword matches
        return is_technical ? 0.8 : 0.4
    }
} 