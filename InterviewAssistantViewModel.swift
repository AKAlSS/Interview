import SwiftUI
import Combine

class InterviewAssistantViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var transcript: String = ""
    @Published var answer: String = ""
    @Published var code: String = ""
    @Published var explanation: String = ""
    @Published var isListening: Bool = false
    @Published var isSplitMode: Bool = false
    
    // Core components
    private let audioCapture = AudioCaptureManager()
    private let questionAnalyzer = QuestionAnalyzer()
    private let answerGenerator = AnswerGenerator(apiKey: "your-openai-api-key")
    private let screenManager = ScreenManager()
    private let appConcealer = AppConcealer()
    private let cursorIntegration = CursorIntegration()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up audio capture callbacks
        audioCapture.transcriptPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcript in
                self?.processTranscript(transcript)
            }
            .store(in: &cancellables)
    }
    
    func startListening() {
        audioCapture.startCapturing()
        isListening = true
    }
    
    func stopListening() {
        audioCapture.stopCapturing()
        isListening = false
    }
    
    func setupSplitMode() {
        screenManager.setupSplitMode()
        isSplitMode = true
        
        // Start cursor integration when in split mode
        cursorIntegration.start()
    }
    
    func exitSplitMode() {
        screenManager.exitSplitMode()
        isSplitMode = false
        
        // Stop cursor integration when exiting split mode
        cursorIntegration.stop()
    }
    
    func hideApp() {
        appConcealer.hideApp()
    }
    
    private func processTranscript(_ transcript: String) {
        self.transcript = transcript
        
        // Analyze the transcript to determine if it's a question
        let analysis = questionAnalyzer.analyze(transcript)
        
        // If it's a technical question, generate an answer
        if analysis.is_technical {
            if analysis.is_coding_question {
                // Generate code and explanation locally for testing
                answerGenerator.generateLocalCodeWithExplanation(transcript)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                        self?.code = result.code
                        self?.explanation = result.explanation
                        self?.answer = ""
                        
                        // Send code to Cursor IDE if in split mode
                        if self?.isSplitMode == true {
                            self?.cursorIntegration.sendToCursor(result.code)
                        }
                    })
                    .store(in: &cancellables)
            } else {
                // Generate technical explanation locally for testing
                answerGenerator.generateLocalAnswer(transcript, analysis)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                        self?.answer = result
                        self?.code = ""
                        self?.explanation = ""
                    })
                    .store(in: &cancellables)
            }
        }
    }
} 