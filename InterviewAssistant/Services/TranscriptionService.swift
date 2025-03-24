import AVFoundation
import Speech
import Foundation

class TranscriptionService: NSObject, SFSpeechRecognizerDelegate {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    var onTranscriptionUpdate: ((String) -> Void)?
    var onFinalTranscription: ((String) -> Void)?
    var isRecording = false
    
    private var lastTranscription: String = ""
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.0 // Seconds of silence to consider as end of speech
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            let speechAuthorized = (status == .authorized)
            
            AVAudioSession.sharedInstance().requestRecordPermission { audioAuthorized in
                DispatchQueue.main.async {
                    completion(speechAuthorized && audioAuthorized)
                }
            }
        }
    }
    
    func startRecording() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "TranscriptionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep audio recording even during recognition
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "TranscriptionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create audio engine"])
        }
        
        // Get the audio input node
        let inputNode = audioEngine.inputNode
        
        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.lastTranscription = transcription
                self.resetSilenceTimer()
                self.onTranscriptionUpdate?(transcription)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if self.isRecording {
                    // Restart recording if we're still supposed to be recording
                    // This ensures continuous recording even if the recognition task ends
                    try? self.startRecording()
                } else {
                    self.onFinalTranscription?(self.lastTranscription)
                }
            }
        }
        
        // Configure the audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        resetSilenceTimer()
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        silenceTimer?.invalidate()
        
        // Deliver final transcription
        if !lastTranscription.isEmpty {
            onFinalTranscription?(lastTranscription)
        }
        
        // Reset
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            // If we've reached silence threshold, consider this the end of speech
            if !self.lastTranscription.isEmpty {
                self.onFinalTranscription?(self.lastTranscription)
                self.lastTranscription = ""
            }
        }
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes
        if !available {
            stopRecording()
        }
    }
} 