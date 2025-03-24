import SwiftUI
import Combine

class InterviewAssistantViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var answer: String = ""
    @Published var code: String = ""
    @Published var explanation: String = ""
    @Published var isListening: Bool = false
    @Published var isSplitMode: Bool = false
    
    private let audioCapture = ZoomAudioCapture()
    private let questionAnalyzer = QuestionAnalyzer()
    private let answerGenerator = AnswerGenerator(apiKey: "your-api-key")
    private let screenManager = ScreenManager()
    private let appConcealer = AppConcealer()
    
    private var currentQuestion = ""
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        setupKeyboardShortcuts()
        appConcealer.setupConcealment()
    }
    
    deinit {
        appConcealer.cleanup()
    }
    
    private func setupBindings() {
        audioCapture.onTranscriptUpdate = { [weak self] newTranscript in
            self?.processTranscript(newTranscript)
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Register keyboard shortcuts for app control
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Toggle split screen mode - Cmd+Shift+S
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 1 {
                self?.toggleSplitMode()
                return nil
            }
            
            // Toggle listening - Cmd+Shift+L
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 37 {
                if self?.isListening == true {
                    self?.stopListening()
                } else {
                    self?.startListening()
                }
                return nil
            }
            
            return event
        }
    }
    
    func startListening() {
        audioCapture.startCapturing()
        isListening = true
    }
    
    func stopListening() {
        audioCapture.stopCapturing()
        isListening = false
    }
    
    func toggleSplitMode() {
        if isSplitMode {
            screenManager.exitSplitMode()
        } else {
            screenManager.setupSplitMode()
        }
        
        isSplitMode = screenManager.isInSplitMode
    }
    
    func prepareForScreenSharing() {
        screenManager.prepareForScreenSharing()
        isSplitMode = true
    }
    
    private func processTranscript(_ newTranscript: String) {
        // Update UI with transcript
        DispatchQueue.main.async {
            self.transcript = newTranscript
        }
        
        // Detect if it's a new question (ended with question mark or pause)
        if newTranscript.hasSuffix("?") || 
           (newTranscript != currentQuestion && newTranscript.split(separator: " ").count > 5) {
            
            currentQuestion = newTranscript
            
            // Analyze question
            let analysis = questionAnalyzer.analyze(newTranscript)
            
            if analysis.is_technical {
                if analysis.is_coding_question {
                    // Generate code with explanation
                    answerGenerator.generateCodeWithExplanation(newTranscript)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { [weak self] result in
                                self?.code = result.code
                                self?.explanation = result.explanation
                                self?.answer = ""
                            }
                        )
                        .store(in: &subscriptions)
                } else {
                    // Generate technical answer
                    answerGenerator.generateTechnicalAnswer(newTranscript, analysis)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { [weak self] result in
                                self?.answer = result
                                self?.code = ""
                                self?.explanation = ""
                            }
                        )
                        .store(in: &subscriptions)
                }
            }
        }
    }
}

struct InterviewAssistantView: View {
    @StateObject var viewModel = InterviewAssistantViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Control panel
            HStack {
                Text("Interview Assistant")
                    .font(.headline)
                
                Spacer()
                
                Button(viewModel.isListening ? "Stop Listening" : "Start Listening") {
                    if viewModel.isListening {
                        viewModel.stopListening()
                    } else {
                        viewModel.startListening()
                    }
                }
                .padding(8)
                .background(viewModel.isListening ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button(viewModel.isSplitMode ? "Exit Split Mode" : "Enter Split Mode") {
                    viewModel.toggleSplitMode()
                }
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Share Screen") {
                    viewModel.prepareForScreenSharing()
                }
                .padding(8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Transcript display
            VStack(alignment: .leading) {
                Text("Transcript:")
                    .font(.subheadline)
                    .bold()
                
                ScrollView {
                    Text(viewModel.transcript)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 100)
            }
            
            // Only show these in the main view when not in split mode
            if !viewModel.isSplitMode {
                if !viewModel.answer.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggested Answer:")
                            .font(.subheadline)
                            .bold()
                        
                        ScrollView {
                            Text(viewModel.answer)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                if !viewModel.code.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Code Solution:")
                            .font(.subheadline)
                            .bold()
                        
                        ScrollView {
                            VStack(alignment: .leading) {
                                Text(viewModel.code)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(8)
                                
                                if !viewModel.explanation.isEmpty {
                                    Text("Explanation:")
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.top, 8)
                                    
                                    Text(viewModel.explanation)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Keyboard shortcuts help
            HStack {
                Text("⌘⇧S: Toggle Split | ⌘⇧L: Toggle Listening | ⌘⌥H: Hide App")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .environmentObject(viewModel)
    }
}

@main
struct InterviewAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            InterviewAssistantView()
        }
    }
} 