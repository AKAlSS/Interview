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
        // Update context with the new question
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
    
    // For testing purposes without API access
    func generateLocalAnswer(_ question: String, _ analysis: QuestionAnalysis) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // Create mock responses based on keywords
            var response = "This is a simulated response for testing purposes."
            
            if question.lowercased().contains("react") {
                response = "React is a JavaScript library for building user interfaces. It uses a component-based architecture and a virtual DOM for efficient rendering. The virtual DOM is a lightweight copy of the actual DOM, which React uses to compute the most efficient way to update the UI when state changes."
            } else if question.lowercased().contains("accessibility") {
                response = "Web accessibility ensures that websites are usable by people with disabilities. Key principles include providing text alternatives for non-text content, creating content that can be presented in different ways, making content easier to see and hear, providing enough time for users to read and use content, and making functionality available from a keyboard."
            } else if question.lowercased().contains("css") {
                response = "CSS (Cascading Style Sheets) is used to style and layout web pages. Modern CSS features include Flexbox and Grid for advanced layouts, CSS Variables for reusable values, and Media Queries for responsive design. Best practices include using a consistent naming convention like BEM, organizing styles logically, and minimizing specificity conflicts."
            }
            
            promise(.success(response))
        }
        .delay(for: .seconds(1), scheduler: RunLoop.main) // Simulate API delay
        .eraseToAnyPublisher()
    }
    
    // For testing purposes without API access
    func generateLocalCodeWithExplanation(_ question: String) -> AnyPublisher<(code: String, explanation: String), Error> {
        return Future<(code: String, explanation: String), Error> { promise in
            var code = ""
            var explanation = ""
            
            if question.lowercased().contains("navigation") {
                code = """
                // Responsive Navigation Component
                import React, { useState } from 'react';
                import './NavBar.css';
                
                function NavBar() {
                  const [isOpen, setIsOpen] = useState(false);
                  
                  const toggleMenu = () => {
                    setIsOpen(!isOpen);
                  };
                  
                  return (
                    <nav className="navbar">
                      <div className="navbar-brand">
                        <a href="/" className="logo">MyWebsite</a>
                        <button 
                          className="navbar-toggle" 
                          onClick={toggleMenu}
                          aria-label="Toggle navigation menu"
                          aria-expanded={isOpen}
                        >
                          <span className="icon-bar"></span>
                          <span className="icon-bar"></span>
                          <span className="icon-bar"></span>
                        </button>
                      </div>
                      
                      <div className={`navbar-menu ${isOpen ? 'active' : ''}`}>
                        <ul className="navbar-links">
                          <li><a href="/">Home</a></li>
                          <li><a href="/about">About</a></li>
                          <li><a href="/services">Services</a></li>
                          <li><a href="/contact">Contact</a></li>
                        </ul>
                      </div>
                    </nav>
                  );
                }
                
                export default NavBar;
                """
                
                explanation = """
                This responsive navigation component includes:
                
                1. State management: Using useState hook to track if the mobile menu is open or closed
                2. Toggle functionality: A button that toggles the menu state when clicked
                3. Conditional classes: The 'active' class is applied to the navbar-menu when isOpen is true
                4. Accessibility: Proper ARIA attributes to make the navigation accessible
                5. Mobile-first approach: The component works on small screens and can be styled to adapt to larger screens
                """
            } else {
                code = """
                // Generic component example
                import React, { useState, useEffect } from 'react';
                
                function ExampleComponent({ initialData }) {
                  const [data, setData] = useState(initialData);
                  const [loading, setLoading] = useState(false);
                  const [error, setError] = useState(null);
                  
                  useEffect(() => {
                    const fetchData = async () => {
                      setLoading(true);
                      try {
                        const response = await fetch('https://api.example.com/data');
                        const result = await response.json();
                        setData(result);
                        setError(null);
                      } catch (err) {
                        setError('Failed to fetch data');
                        console.error(err);
                      } finally {
                        setLoading(false);
                      }
                    };
                    
                    fetchData();
                  }, []);
                  
                  if (loading) return <p>Loading...</p>;
                  if (error) return <p>Error: {error}</p>;
                  
                  return (
                    <div className="example-component">
                      <h2>Data Display</h2>
                      <pre>{JSON.stringify(data, null, 2)}</pre>
                    </div>
                  );
                }
                
                export default ExampleComponent;
                """
                
                explanation = """
                This is a generic React component that demonstrates several key patterns:
                
                1. State management: Using useState for component state
                2. Side effects: Using useEffect for data fetching
                3. Error handling: Managing loading and error states
                4. Conditional rendering: Showing different UI based on state
                5. Props usage: Accepting and utilizing props
                """
            }
            
            promise(.success((code: code, explanation: explanation)))
        }
        .delay(for: .seconds(1.5), scheduler: RunLoop.main) // Simulate API delay
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