// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

struct InterviewAssistantCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "interview-assistant",
        abstract: "A CLI tool to assist with technical interviews",
        subcommands: [Listen.self, Answer.self, QuickHelp.self, Configure.self]
    )
    
    // Main command just shows help
    func run() throws {
        InterviewAssistantCLI.helpMessage()
    }
    
    // MARK: - Listen Command
    
    struct Listen: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Listen to audio and transcribe interview questions"
        )
        
        @Option(name: .shortAndLong, help: "Duration in seconds to listen (default: runs until stopped)")
        var duration: Int?
        
        @Flag(name: .shortAndLong, help: "Process and answer questions automatically")
        var autoAnswer: Bool = false
        
        func run() throws {
            print("🎙️ Starting audio capture...")
            
            let apiKey = try loadAPIKey()
            let audioManager = AudioCaptureManager(apiKey: apiKey)
            let analyzer = QuestionAnalyzer()
            let answerGenerator = AnswerGenerator(apiKey: apiKey)
            
            // Set up signal handler to stop gracefully
            signal(SIGINT) { _ in
                print("\n\n🛑 Stopping audio capture...")
                exit(0)
            }
            
            // Start audio capture
            var transcription = ""
            
            // Create a semaphore to wait for completion if duration is provided
            let semaphore = DispatchSemaphore(value: 0)
            
            // Set up a dispatch queue for audio processing
            let processingQueue = DispatchQueue(label: "com.interviewassistant.processing")
            
            // Start capturing audio
            audioManager.startCapturing()
            
            // Set timeout if duration was provided
            if let duration = duration {
                print("⏱️ Will listen for \(duration) seconds...")
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(duration)) {
                    print("\n\n⏱️ Time's up! Stopping...")
                    semaphore.signal()
                }
            }
            
            // Handle transcriptions
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TranscriptionUpdated"),
                object: nil,
                queue: .main
            ) { notification in
                if let text = notification.userInfo?["text"] as? String {
                    transcription = text
                    print("\r\nQ: \(text)")
                    
                    if self.autoAnswer {
                        processingQueue.async {
                            let analysis = analyzer.analyze(text)
                            if analysis.is_technical || analysis.is_coding_question {
                                print("\nAnalyzing question...")
                                answerGenerator.generateAnswer(for: text, questionType: analysis.question_type) { result in
                                    switch result {
                                    case .success(let answer):
                                        print("\n\n📝 Answer:\n\(answer)\n")
                                    case .failure(let error):
                                        print("\n❌ Error generating answer: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Wait for completion if duration was provided, otherwise run until interrupted
            if duration != nil {
                semaphore.wait()
                audioManager.stopCapturing()
            } else {
                // This will run until SIGINT (Ctrl+C)
                dispatchMain()
            }
        }
    }
    
    // MARK: - Answer Command
    
    struct Answer: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Generate an answer for a technical question"
        )
        
        @Argument(help: "The question to answer")
        var question: String
        
        @Option(name: .shortAndLong, help: "Type of question (algorithm, data_structure, system_design, frontend, general_technical)")
        var type: String?
        
        func run() throws {
            print("📝 Generating answer for: \(question)")
            
            let apiKey = try loadAPIKey()
            let analyzer = QuestionAnalyzer()
            let answerGenerator = AnswerGenerator(apiKey: apiKey)
            
            // Analyze the question if type wasn't provided
            let questionType = type ?? {
                let analysis = analyzer.analyze(question)
                print("Question analyzed as: \(analysis.question_type)")
                return analysis.question_type
            }()
            
            let semaphore = DispatchSemaphore(value: 0)
            
            answerGenerator.generateAnswer(for: question, questionType: questionType) { result in
                switch result {
                case .success(let answer):
                    print("\nAnswer:\n\(answer)")
                case .failure(let error):
                    print("\n❌ Error: \(error.localizedDescription)")
                }
                semaphore.signal()
            }
            
            semaphore.wait()
        }
    }
    
    // MARK: - QuickHelp Command
    
    struct QuickHelp: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "quick",
            abstract: "Get quick help during an interview"
        )
        
        @Argument(help: "Keywords to look up (e.g., 'binary search', 'react hooks')")
        var keywords: [String]
        
        func run() throws {
            let query = keywords.joined(separator: " ")
            print("🔍 Quick lookup: \(query)")
            
            let apiKey = try loadAPIKey()
            let answerGenerator = AnswerGenerator(apiKey: apiKey)
            
            let semaphore = DispatchSemaphore(value: 0)
            
            answerGenerator.generateQuickHelp(for: query) { result in
                switch result {
                case .success(let answer):
                    print("\n\(answer)")
                case .failure(let error):
                    print("\n❌ Error: \(error.localizedDescription)")
                }
                semaphore.signal()
            }
            
            semaphore.wait()
        }
    }
    
    // MARK: - Configure Command
    
    struct Configure: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Configure the CLI tool"
        )
        
        @Option(name: .shortAndLong, help: "OpenAI API Key")
        var apiKey: String?
        
        func run() throws {
            if let apiKey = apiKey {
                // Save API key to configuration file
                try saveAPIKey(apiKey)
                print("✅ API key configured successfully")
            } else {
                // Show current configuration
                do {
                    let apiKey = try loadAPIKey()
                    print("Current API Key: \(apiKey.prefix(4))...\(apiKey.suffix(4))")
                } catch {
                    print("❌ No API key configured. Use --api-key to set one.")
                }
            }
        }
    }
}

// MARK: - Helper Functions

/// Load API key from configuration file
func loadAPIKey() throws -> String {
    let fileManager = FileManager.default
    let configDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".interview-assistant")
    let configFile = configDir.appendingPathComponent("config.json")
    
    guard fileManager.fileExists(atPath: configFile.path) else {
        throw ValidationError("API key not configured. Run 'interview-assistant configure --api-key YOUR_KEY'")
    }
    
    let data = try Data(contentsOf: configFile)
    guard let config = try? JSONSerialization.jsonObject(with: data) as? [String: String],
          let apiKey = config["api_key"], !apiKey.isEmpty else {
        throw ValidationError("Invalid configuration. Run 'interview-assistant configure --api-key YOUR_KEY'")
    }
    
    return apiKey
}

/// Save API key to configuration file
func saveAPIKey(_ apiKey: String) throws {
    let fileManager = FileManager.default
    let configDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".interview-assistant")
    let configFile = configDir.appendingPathComponent("config.json")
    
    // Create directory if it doesn't exist
    if !fileManager.fileExists(atPath: configDir.path) {
        try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
    }
    
    // Save config
    let config = ["api_key": apiKey]
    let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted])
    try data.write(to: configFile)
    
    // Set appropriate permissions
    try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configFile.path)
}

// MARK: - Audio Capture Manager

class AudioCaptureManager {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func startCapturing() {
        // In a real implementation, this would use AVFoundation
        // For this CLI prototype, we'll use simulated transcriptions
        
        print("🎙️ Audio capture started (simulated)")
        
        // Simulate periodic transcriptions
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.simulateTranscription()
        }
    }
    
    func stopCapturing() {
        print("🎙️ Audio capture stopped")
    }
    
    private func simulateTranscription() {
        // In a real implementation, this would use the Whisper API
        // For this prototype, we'll simulate random technical questions
        
        let questions = [
            "Can you explain how binary search trees work?",
            "What's the difference between let and var in Swift?",
            "How would you implement a linked list in Swift?",
            "What are React hooks and how do they work?",
            "Can you explain the MVC design pattern?",
            "What's the time complexity of QuickSort?",
            "How does dependency injection work?",
            "What's the difference between TCP and UDP?"
        ]
        
        let randomQuestion = questions.randomElement() ?? "How does this algorithm work?"
        
        // Post notification with the transcription
        NotificationCenter.default.post(
            name: NSNotification.Name("TranscriptionUpdated"),
            object: nil,
            userInfo: ["text": randomQuestion]
        )
    }
}

// MARK: - Question Analyzer
class QuestionAnalyzer {
    func analyze(_ transcript: String) -> QuestionAnalysis {
        // Simple analysis for the CLI version
        let lowercased = transcript.lowercased()
        
        let isTechnical = lowercased.contains("algorithm") || 
                          lowercased.contains("code") || 
                          lowercased.contains("data structure") || 
                          lowercased.contains("implement") ||
                          lowercased.contains("design") ||
                          lowercased.contains("javascript") ||
                          lowercased.contains("swift") ||
                          lowercased.contains("react")
        
        let isCoding = lowercased.contains("implement") || 
                       lowercased.contains("code") || 
                       lowercased.contains("write") ||
                       lowercased.contains("function")
        
        // Determine question type
        let questionType: String
        if lowercased.contains("algorithm") || lowercased.contains("complexity") {
            questionType = "algorithm"
        } else if lowercased.contains("data structure") || lowercased.contains("array") || lowercased.contains("linked list") {
            questionType = "data_structure"
        } else if lowercased.contains("design") && (lowercased.contains("system") || lowercased.contains("architecture")) {
            questionType = "system_design"
        } else if lowercased.contains("css") || lowercased.contains("html") || lowercased.contains("ui") || lowercased.contains("react") {
            questionType = "frontend"
        } else {
            questionType = "general_technical"
        }
        
        return QuestionAnalysis(
            is_technical: isTechnical,
            is_coding_question: isCoding,
            is_follow_up: false,
            question_type: questionType,
            keywords_detected: [],
            context: "",
            transcript: transcript
        )
    }
}

// MARK: - Answer Generator
class AnswerGenerator {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateAnswer(for question: String, questionType: String, completion: @escaping (Result<String, Error>) -> Void) {
        // In a real implementation, this would use the OpenAI API
        // For this prototype, we'll simulate an answer
        
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            let response = self.simulateAnswer(for: question, questionType: questionType)
            completion(.success(response))
        }
    }
    
    func generateQuickHelp(for query: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Generate a shorter, more concise response for quick help
        
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            let response = self.simulateQuickHelp(for: query)
            completion(.success(response))
        }
    }
    
    private func simulateAnswer(for question: String, questionType: String) -> String {
        // This simulates a potential answer, in a real implementation, this would call the OpenAI API
        
        switch questionType {
        case "algorithm":
            return "For algorithms, you generally want to consider:\n\n1. Time complexity: Big O notation\n2. Space complexity: Memory usage\n3. Edge cases\n4. Input validation\n\nFor example, if implementing a sorting algorithm, you might consider:\n- Stability requirements\n- Expected input characteristics\n- Available memory\n- Parallelization possibilities\n\nWould you like me to elaborate on any specific algorithm?"
            
        case "data_structure":
            return "When working with data structures, consider these key aspects:\n\n1. Access patterns: How will you be accessing the data?\n2. Modification frequency: Will you be mostly reading or writing?\n3. Memory constraints: Is space a concern?\n4. Operations needed: Search, insert, delete, traverse?\n\nFor example, if you need fast lookups by key, a hashmap might be ideal. If you need to maintain order and have efficient insertions/deletions at both ends, a double-ended queue could work well."
            
        case "system_design":
            return "For system design questions, follow this framework:\n\n1. Clarify requirements and constraints\n2. Make reasonable estimates (users, storage, bandwidth)\n3. Define API endpoints\n4. Design high-level architecture\n5. Deep dive into components\n6. Identify bottlenecks and solutions\n\nAlways consider: scalability, reliability, availability, consistency, performance, and cost."
            
        case "frontend":
            return "For frontend development, consider these key principles:\n\n1. User experience and accessibility\n2. Performance optimization\n3. Component design and reusability\n4. State management\n5. Responsive design principles\n\nSpecific technologies like React focus on a component-based architecture with unidirectional data flow. CSS frameworks like Flexbox and Grid help with layout challenges."
            
        default:
            return "For technical questions, it's important to:\n\n1. Understand the core concepts first\n2. Be able to explain with simple examples\n3. Know the trade-offs of different approaches\n4. Have experience with real-world applications\n\nSpecific technologies all have their pros and cons, but fundamentals usually transfer well between them."
        }
    }
    
    private func simulateQuickHelp(for query: String) -> String {
        // Generate a shorter response for quick help
        let lowercased = query.lowercased()
        
        if lowercased.contains("binary search") {
            return "Binary Search: O(log n) algorithm for sorted arrays. Divide array in half each time by comparing target with middle element."
        } else if lowercased.contains("react hooks") {
            return "React Hooks: Functions that let you use state and lifecycle features in functional components. useState(), useEffect(), useContext() are common ones."
        } else if lowercased.contains("big o") {
            return "Big O Notation: Describes worst-case time/space complexity. Common ones:\nO(1): Constant\nO(log n): Logarithmic\nO(n): Linear\nO(n log n): Linearithmic\nO(n²): Quadratic\nO(2ⁿ): Exponential"
        } else if lowercased.contains("rest api") {
            return "REST API: Architecture for networked applications. Uses HTTP methods (GET, POST, PUT, DELETE), stateless operations, and resources identified by URLs."
        } else {
            return "Quick reference for '\(query)':\n• Key concept: Refers to a common pattern in software development\n• Used for: Solving specific technical challenges\n• Best practices: Follow the principle of least surprise\n• Related topics: Design patterns, algorithms, data structures"
        }
    }
}

// MARK: - Question Analysis Model
struct QuestionAnalysis {
    let is_technical: Bool
    let is_coding_question: Bool
    let is_follow_up: Bool
    let question_type: String
    let keywords_detected: [String]
    let context: String
    let transcript: String
}

// MARK: - Run the CLI

InterviewAssistantCLI.main()
