import Foundation
import Combine

class AnswerGenerator {
    private let apiKey: String
    private let urlSession = URLSession.shared
    private var context: [String] = []
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateTechnicalAnswer(_ question: String, _ analysis: QuestionAnalysis) -> AnyPublisher<String, Error> {
        // Update context
        updateContext(question: question)
        
        // Create prompt based on the analysis
        let prompt = createPromptForTechnicalQuestion(question, analysis)
        
        // Make API request to GPT-4
        return callGPT(prompt: prompt)
            .map { response in
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Update context with the answer
                    self.updateContext(answer: content)
                    return content
                } else {
                    return "Sorry, I couldn't generate a response for this question."
                }
            }
            .eraseToAnyPublisher()
    }
    
    func generateCodeWithExplanation(_ question: String) -> AnyPublisher<(code: String, explanation: String), Error> {
        // Update context
        updateContext(question: question)
        
        // Create prompt for code generation
        let prompt = createPromptForCodeGeneration(question)
        
        // Make API request to GPT-4
        return callGPT(prompt: prompt)
            .map { response in
                if let choices = response["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse code blocks and explanation
                    let (code, explanation) = self.parseCodeAndExplanation(content)
                    
                    // Update context
                    self.updateContext(answer: "Code: " + code.prefix(100) + "...")
                    
                    return (code: code, explanation: explanation)
                } else {
                    return (code: "// Error generating code", 
                           explanation: "Sorry, I couldn't generate code for this question.")
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func parseCodeAndExplanation(_ content: String) -> (String, String) {
        // Parse code blocks from markdown
        let codeBlockPattern = "```(?:javascript|js|html|css|typescript|ts)([\\s\\S]*?)```"
        let regex = try! NSRegularExpression(pattern: codeBlockPattern)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        
        var code = ""
        if let match = regex.firstMatch(in: content, range: range) {
            let codeRange = match.range(at: 1)
            if let codeSubstringRange = Range(codeRange, in: content) {
                code = String(content[codeSubstringRange])
            }
        }
        
        // Everything outside code blocks is considered explanation
        let explanation = content.replacingOccurrences(
            of: codeBlockPattern, 
            with: "", 
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (code, explanation)
    }
    
    private func createPromptForTechnicalQuestion(_ question: String, _ analysis: QuestionAnalysis) -> String {
        var prompt = """
        You are an expert Senior UX Developer in a technical interview. 
        Provide a comprehensive, technically accurate response to the following question:
        
        Question: \(question)
        """
        
        if !analysis.keywords_detected.isEmpty {
            prompt += "\n\nFocus on these key concepts: \(analysis.keywords_detected.joined(separator: ", "))"
        }
        
        if analysis.is_follow_up {
            prompt += "\n\nThis is a follow-up question. Previous context: \(analysis.context)"
        }
        
        prompt += "\n\nYour response should be detailed but concise, showcasing senior-level understanding."
        
        return prompt
    }
    
    private func createPromptForCodeGeneration(_ question: String) -> String {
        return """
        You are an expert Senior UX Developer in a technical interview.
        Write clean, efficient, production-quality code for the following task:
        
        \(question)
        
        Provide your solution in this format:
        1. First, the complete code solution in a single markdown code block
        2. Then, a detailed line-by-line explanation of how the code works
        
        Focus on creating elegant, maintainable code that follows best practices for UX development.
        """
    }
    
    private func callGPT(prompt: String) -> AnyPublisher<[String: Any], Error> {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert Senior UX Developer in a technical interview."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        return urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [String: Any].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    private func updateContext(question: String? = nil, answer: String? = nil) {
        if let question = question {
            context.append("Q: \(question)")
        }
        
        if let answer = answer {
            context.append("A: \(answer)")
        }
        
        // Keep only the last 4 Q&A pairs
        if context.count > 8 {
            context.removeFirst(context.count - 8)
        }
    }
}

// Add JSON decoder extension for Dictionary
extension JSONDecoder {
    func decode(type: [String: Any].Type, from data: Data) throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
    }
} 