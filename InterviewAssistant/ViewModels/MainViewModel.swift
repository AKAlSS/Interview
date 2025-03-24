import AppKit
import Foundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    // Services
    private var transcriptionService: TranscriptionService
    private var aiService: AIService?
    private var cursorIntegration = CursorIntegration()
    private var screenManager = ScreenManager.shared
    
    // State
    @Published var currentTranscription: String = ""
    @Published var currentAnswer: String = ""
    @Published var isScreenSharingActive: Bool = false
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    // Settings
    @AppStorage("openAIAPIKey") var apiKey: String = ""
    @AppStorage("autoProcessQuestions") var autoProcessQuestions: Bool = false
    @AppStorage("useSimulatedResponses") var useSimulatedResponses: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private var nsWindow: NSWindow? {
        // Get the SwiftUI window for display management
        NSApplication.shared.windows.first
    }
    
    init() {
        // Initialize services
        transcriptionService = TranscriptionService(apiKey: apiKey)
        
        if !apiKey.isEmpty {
            aiService = AIService(apiKey: apiKey)
        }
        
        // Set up transcription handlers
        setupTranscriptionHandlers()
        
        // Setup screen sharing detection
        setupScreenSharingMonitoring()
    }
    
    // MARK: - Setup
    
    func setupTranscriptionHandlers() {
        // Listen for partial transcription updates
        transcriptionService.onTranscriptionUpdate = { [weak self] text in
            DispatchQueue.main.async {
                self?.currentTranscription = text
                
                // Auto-process questions if enabled
                if self?.autoProcessQuestions == true && !text.isEmpty {
                    if let questionAnalyzer = self?.aiService?.questionAnalyzer,
                       questionAnalyzer.isLikelyQuestion(text) {
                        self?.processTranscription() { _ in }
                    }
                }
            }
        }
        
        // Listen for final transcriptions
        transcriptionService.onFinalTranscription = { [weak self] text in
            DispatchQueue.main.async {
                self?.currentTranscription = text
            }
        }
    }
    
    func setupWindowManagement() {
        if let window = nsWindow {
            WindowManagementService.shared.registerMainWindow(window)
        }
    }
    
    func setupScreenSharingMonitoring() {
        // Subscribe to screen sharing updates
        screenManager.$isScreenSharingActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSharing in
                self?.isScreenSharingActive = isSharing
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permissions
    
    func requestPermissions() {
        transcriptionService.requestPermissions { granted in
            if !granted {
                // Handle permission denial (show alert, etc.)
                DispatchQueue.main.async {
                    self.errorMessage = "Speech recognition permissions were denied"
                }
            }
        }
    }
    
    // MARK: - Recording Controls
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            do {
                try startRecording()
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    func startRecording() throws {
        do {
            try transcriptionService.startRecording()
            isRecording = true
            errorMessage = nil
        } catch {
            isRecording = false
            throw error
        }
    }
    
    func stopRecording() {
        transcriptionService.stopRecording()
        isRecording = false
    }
    
    // MARK: - Processing
    
    func processTranscription(completion: @escaping (Bool) -> Void = { _ in }) {
        guard !currentTranscription.isEmpty else {
            completion(false)
            return
        }
        
        // Don't start another processing if one is already in progress
        guard !isProcessing else {
            completion(false)
            return
        }
        
        isProcessing = true
        
        // Initialize AI service if needed
        if aiService == nil && !apiKey.isEmpty {
            aiService = AIService(apiKey: apiKey)
        }
        
        guard let aiService = aiService else {
            DispatchQueue.main.async {
                self.errorMessage = "AI Service not initialized - missing API key"
                self.isProcessing = false
                completion(false)
            }
            return
        }
        
        // First analyze the question type
        aiService.analyzeQuestion(currentTranscription) { [weak self] questionType in
            guard let self = self else { return }
            
            // Then generate an answer based on the question type
            self.aiService?.generateAnswer(for: self.currentTranscription, questionType: questionType) { result in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    switch result {
                    case .success(let answer):
                        self.currentAnswer = answer
                        self.errorMessage = nil
                        completion(true)
                        
                    case .failure(let error):
                        print("Failed to generate answer: \(error.localizedDescription)")
                        self.errorMessage = "Error: \(error.localizedDescription)"
                        completion(false)
                    }
                }
            }
        }
    }
    
    // MARK: - Cursor Integration
    
    func sendToCursor() {
        guard !currentAnswer.isEmpty else { return }
        
        // Format the answer for Cursor
        let formattedAnswer = currentAnswer
        
        // Send to Cursor via clipboard
        cursorIntegration.sendToCursor(formattedAnswer)
    }
    
    // MARK: - Testing Helpers
    
    func simulateQuestion(_ question: String) {
        currentTranscription = question
        
        // Process the question automatically if auto-processing is enabled
        if autoProcessQuestions {
            processTranscription() { _ in }
        }
    }
    
    func clearTranscription() {
        currentTranscription = ""
    }
    
    func clearAnswer() {
        currentAnswer = ""
    }
} 