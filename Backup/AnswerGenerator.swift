import Foundation
import Combine

class AnswerGenerator {
    func generateLocalAnswer(_ question: String, _ analysis: QuestionAnalysis) -> AnyPublisher<String, Error> {
        // Local mock responses for testing without API
        return Future<String, Error> { promise in
            let response: String
            
            if question.lowercased().contains("react") {
                response = "React is a JavaScript library for building user interfaces. It uses a component-based architecture and virtual DOM for efficient rendering. Key concepts include JSX, props, state, and hooks."
            } else if question.lowercased().contains("accessibility") {
                response = "Web accessibility ensures that websites and applications can be used by people with disabilities. Key principles include providing text alternatives, keyboard navigation, sufficient color contrast, and ARIA attributes."
            } else {
                response = "This is a simulated response for testing purposes. In production, this would use the OpenAI API to generate a real answer based on the question: \"\(question)\""
            }
            
            promise(.success(response))
        }
        .delay(for: .seconds(1), scheduler: RunLoop.main) // Simulate API delay
        .eraseToAnyPublisher()
    }

    func generateLocalCodeWithExplanation(_ question: String) -> AnyPublisher<(code: String, explanation: String), Error> {
        // Local mock code responses for testing
        return Future<(code: String, explanation: String), Error> { promise in
            let code = """
            function ResponsiveNavbar() {
              const [isOpen, setIsOpen] = useState(false);
              
              return (
                <nav className="navbar">
                  <div className="logo">Brand</div>
                  <button 
                    className="menu-toggle" 
                    onClick={() => setIsOpen(!isOpen)}
                  >
                    Menu
                  </button>
                  <ul className={`nav-links ${isOpen ? 'active' : ''}`}>
                    <li><a href="#">Home</a></li>
                    <li><a href="#">About</a></li>
                    <li><a href="#">Services</a></li>
                    <li><a href="#">Contact</a></li>
                  </ul>
                </nav>
              );
            }
            """
            
            let explanation = """
            This is a React functional component that implements a responsive navigation bar:

            1. We use useState to track if the mobile menu is open or closed
            2. The component returns a nav element with a logo, toggle button, and navigation links
            3. The button toggles the 'isOpen' state when clicked
            4. We conditionally apply the 'active' class to the nav-links based on the state
            5. This pattern creates a responsive navbar that works on both mobile and desktop
            """
            
            promise(.success((code: code, explanation: explanation)))
        }
        .delay(for: .seconds(1.5), scheduler: RunLoop.main) // Simulate API delay
        .eraseToAnyPublisher()
    }
} 