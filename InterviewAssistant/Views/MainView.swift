import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var showSettings = false
    @State private var showAPIKeyAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Top bar with status indicators
                HStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.gray)
                        .frame(width: 12, height: 12)
                    
                    Text(isRecording ? "Recording" : "Ready")
                        .font(.caption)
                    
                    Spacer()
                    
                    if viewModel.isScreenSharingActive {
                        Label("Screen Sharing Active", systemImage: "eye.slash")
                            .font(.caption)
                            .foreground(Color.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                Divider()
                
                // Main content area
                VStack(spacing: 20) {
                    // Transcription section
                    VStack(alignment: .leading) {
                        Text("Question")
                            .font(.headline)
                        
                        ScrollView {
                            Text(viewModel.currentTranscription.isEmpty ? "No question detected yet..." : viewModel.currentTranscription)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .animation(.default, value: viewModel.currentTranscription)
                        }
                        .frame(height: 100)
                    }
                    
                    // Answer section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Response")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !viewModel.currentAnswer.isEmpty {
                                Button(action: {
                                    viewModel.sendToCursor()
                                }) {
                                    Label("Send to Cursor", systemImage: "arrow.right.doc.on.clipboard")
                                        .font(.caption)
                                }
                                .buttonStyle(BorderedButtonStyle())
                                .controlSize(.small)
                            }
                        }
                        
                        if isProcessing {
                            ProgressView("Generating response...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ScrollView {
                                Text(viewModel.currentAnswer.isEmpty ? "No response generated yet..." : viewModel.currentAnswer)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack {
                        Button(action: {
                            toggleRecording()
                        }) {
                            Label(isRecording ? "Stop" : "Start", systemImage: isRecording ? "stop.circle" : "mic.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(isRecording ? .bordered : .borderedProminent)
                        .controlSize(.large)
                        .disabled(isProcessing)
                        
                        Button(action: {
                            if !viewModel.currentTranscription.isEmpty {
                                processCurrentQuestion()
                            }
                        }) {
                            Label("Process", systemImage: "play.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(viewModel.currentTranscription.isEmpty || isProcessing)
                    }
                }
                .padding()
            }
            .navigationTitle("Interview Assistant")
            .sheet(isPresented: $showSettings) {
                SettingsView(apiKey: $viewModel.apiKey)
            }
            .alert("OpenAI API Key Required", isPresented: $showAPIKeyAlert) {
                Button("OK") {
                    showSettings = true
                }
            } message: {
                Text("Please enter your OpenAI API key in the settings to use this app.")
            }
            .onAppear {
                checkAPIKey()
                viewModel.setupWindowManagement()
                viewModel.setupNotifications()
                viewModel.requestPermissions()
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            viewModel.stopRecording()
            isRecording = false
        } else {
            do {
                try viewModel.startRecording()
                isRecording = true
            } catch {
                print("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func processCurrentQuestion() {
        isProcessing = true
        
        viewModel.processTranscription { success in
            isProcessing = false
            
            if success {
                // Automatically stop recording after successfully processing
                if isRecording {
                    toggleRecording()
                }
            }
        }
    }
    
    private func checkAPIKey() {
        if viewModel.apiKey.isEmpty {
            showAPIKeyAlert = true
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 