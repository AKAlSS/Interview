import Foundation

enum QuestionType {
    case technical
    case nonTechnical
    case codingRelated
    case unknown
}

class AIService {
    private let openAIAPIKey: String
    private let openAIModel: String
    private let analyzeEndpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String, model: String = "gpt-4") {
        self.openAIAPIKey = apiKey
        self.openAIModel = model
    }
    
    // Analyze the text to determine if it's a technical question
    func analyzeQuestion(_ text: String, completion: @escaping (QuestionType) -> Void) {
        let prompt = """
        Analyze the following question and determine if it's a technical programming question, a coding-related question, or a non-technical question.
        
        Question: \(text)
        
        Respond with exactly one of these categories:
        "TECHNICAL" - For questions about programming concepts, algorithms, data structures, system design, etc.
        "CODING" - For questions that ask for code or implementation details
        "NON-TECHNICAL" - For behavioral, process, non-programming questions
        "UNKNOWN" - If unable to determine
        """
        
        sendPrompt(prompt) { result in
            switch result {
            case .success(let response):
                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                
                if trimmedResponse.contains("TECHNICAL") {
                    completion(.technical)
                } else if trimmedResponse.contains("CODING") {
                    completion(.codingRelated)
                } else if trimmedResponse.contains("NON-TECHNICAL") {
                    completion(.nonTechnical)
                } else {
                    completion(.unknown)
                }
                
            case .failure:
                completion(.unknown)
            }
        }
    }
    
    // Generate an answer to the question
    func generateAnswer(for question: String, questionType: QuestionType, completion: @escaping (Result<String, Error>) -> Void) {
        var prompt = ""
        
        switch questionType {
        case .technical:
            prompt = """
            You are an expert software engineer helping with a technical interview question.
            Provide a clear, comprehensive answer to the following technical question.
            Focus on key concepts, best practices, and examples where appropriate.
            
            Question: \(question)
            """
            
        case .codingRelated:
            prompt = """
            You are an expert software engineer helping with a coding question in an interview.
            Write clean, efficient, and well-commented code to solve the following problem.
            Include explanations of your approach, time/space complexity, and any trade-offs.
            
            Question: \(question)
            """
            
        case .nonTechnical, .unknown:
            prompt = """
            You are helping with an interview question. Provide a thoughtful, concise answer to the following:
            
            Question: \(question)
            """
        }
        
        sendPrompt(prompt, completion: completion)
    }
    
    // Send prompt to OpenAI API
    private func sendPrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the request
        guard let url = URL(string: analyzeEndpoint) else {
            completion(.failure(NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 800
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else {
                    // Try to get error message if available
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: message])))
                        }
                    } else {
                        throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
} 