import Foundation

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