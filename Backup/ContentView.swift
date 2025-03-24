import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: InterviewAssistantViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Top control bar
            HStack {
                Text("Technical Interview Assistant")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Listening toggle
                    Button(viewModel.isListening ? "Stop Listening" : "Start Listening") {
                        viewModel.isListening ? viewModel.stopListening() : viewModel.startListening()
                    }
                    .padding(8)
                    .background(viewModel.isListening ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // Split mode toggle
                    Button(viewModel.isSplitMode ? "Exit Split Mode" : "Enter Split Mode") {
                        viewModel.isSplitMode ? viewModel.exitSplitMode() : viewModel.setupSplitMode()
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // Hide button
                    Button("Hide (⌘⌥H)") {
                        viewModel.hideApp()
                    }
                    .padding(8)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.bottom, 8)
            
            // Transcript section
            VStack(alignment: .leading) {
                Text("Interview Transcript")
                    .font(.headline)
                
                ScrollView {
                    Text(viewModel.transcript)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 100)
            }
            
            // Results section - only shown in full mode, not split mode
            if !viewModel.isSplitMode {
                VStack(spacing: 12) {
                    // Answer section
                    if !viewModel.answer.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Answer")
                                .font(.headline)
                            
                            ScrollView {
                                Text(viewModel.answer)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Code section
                    if !viewModel.code.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Code Solution")
                                .font(.headline)
                            
                            ScrollView {
                                Text(viewModel.code)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Explanation section
                        if !viewModel.explanation.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Explanation")
                                    .font(.headline)
                                
                                ScrollView {
                                    Text(viewModel.explanation)
                                        .padding()
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
            
            // Keyboard shortcut help
            HStack {
                Text("⌘⇧L: Toggle Listening | ⌘⇧S: Split Mode | ⌘⌥H: Hide App")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Add test panel at the bottom for local testing
            TestPanel()
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct TestPanel: View {
    @EnvironmentObject var viewModel: InterviewAssistantViewModel
    @State private var testQuestion: String = ""
    
    var body: some View {
        VStack {
            Divider()
                .padding(.vertical)
            
            Text("Test Interface")
                .font(.headline)
            
            HStack {
                TextField("Type a test question...", text: $testQuestion)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    if !testQuestion.isEmpty {
                        // Simulate received transcript
                        if let audioCapture = viewModel.audioCapture as? AudioCaptureManager {
                            audioCapture.simulateTranscript(testQuestion)
                        }
                        testQuestion = ""
                    }
                }
                .disabled(testQuestion.isEmpty)
            }
            
            HStack {
                Button("Test Technical Question") {
                    if let audioCapture = viewModel.audioCapture as? AudioCaptureManager {
                        audioCapture.simulateTranscript("Can you explain how React's virtual DOM works?")
                    }
                }
                
                Button("Test Coding Question") {
                    if let audioCapture = viewModel.audioCapture as? AudioCaptureManager {
                        audioCapture.simulateTranscript("Can you implement a responsive navigation component with React?")
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 