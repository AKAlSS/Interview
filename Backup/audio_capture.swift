import AVFoundation
import Speech

class ZoomAudioCapture {
    private var audioEngine: AVAudioEngine
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // Add Whisper API client for better accuracy with technical terms
    private let whisperClient = WhisperClient(apiKey: "your-whisper-api-key")
    
    var onTranscriptUpdate: ((String) -> Void)?
    private var bufferAudioData = Data()
    private var isProcessingWithWhisper = false
    
    init() {
        audioEngine = AVAudioEngine()
        setupAudioSession()
    }
    
    func startCapturing() {
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            
            // Setup audio capture from system audio using BlackHole
            let inputNode = self?.audioEngine.inputNode
            let recordingFormat = inputNode?.outputFormat(forBus: 0)
            
            // Install tap on the audio engine
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                // For Apple's speech recognition
                self?.recognitionRequest?.append(buffer)
                
                // For Whisper API (collect audio for periodic processing)
                let channelData = buffer.floatChannelData?[0]
                if let channelData = channelData {
                    let channelBuffer = UnsafeBufferPointer(start: channelData, 
                                                           count: Int(buffer.frameLength))
                    let audioData = Data(bytes: channelBuffer.baseAddress!, 
                                        count: Int(buffer.frameLength) * MemoryLayout<Float>.size)
                    self?.bufferAudioData.append(audioData)
                    
                    // When we have enough data (about 5 seconds at 16kHz)
                    if self?.bufferAudioData.count ?? 0 > 160000 && !(self?.isProcessingWithWhisper ?? true) {
                        self?.processAudioWithWhisper()
                    }
                }
            }
            
            // Set up Apple's speech recognition for initial quick results
            self?.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            self?.recognitionRequest?.shouldReportPartialResults = true
            
            self?.recognitionTask = self?.speechRecognizer?.recognitionTask(
                with: self!.recognitionRequest!,
                resultHandler: { [weak self] result, error in
                    if let result = result {
                        // Use Apple's recognition for immediate feedback
                        // Final results will come from Whisper
                        self?.onTranscriptUpdate?(result.bestTranscription.formattedString)
                    }
                })
            
            // Start audio engine
            try? self?.audioEngine.start()
        }
    }
    
    private func processAudioWithWhisper() {
        isProcessingWithWhisper = true
        
        // Convert buffer to format Whisper expects
        let audioForWhisper = convertBufferForWhisper(bufferAudioData)
        
        // Process with Whisper API (better for technical terms)
        whisperClient.transcribe(audioData: audioForWhisper) { [weak self] result in
            if let transcript = result {
                DispatchQueue.main.async {
                    self?.onTranscriptUpdate?(transcript)
                }
            }
            
            // Keep last 2 seconds of audio for context
            self?.bufferAudioData = self?.bufferAudioData.suffix(32000) ?? Data()
            self?.isProcessingWithWhisper = false
        }
    }
    
    private func convertBufferForWhisper(_ buffer: Data) -> Data {
        // Convert audio format as needed for Whisper API
        // This would handle sample rate conversion, format changes, etc.
        // For now, returning the original buffer
        return buffer
    }
    
    private func setupAudioSession() {
        // Configure for BlackHole virtual audio driver
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            // Configure audio engine to use BlackHole as input
            let inputNode = audioEngine.inputNode
            // Here you would select the BlackHole device
            // This requires additional setup outside this code
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func stopCapturing() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}

// Whisper API client
class WhisperClient {
    private let apiKey: String
    private let session = URLSession.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func transcribe(audioData: Data, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartFormData(boundary: boundary, audioData: audioData)
        request.httpBody = httpBody
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    completion(text)
                } else {
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func createMultipartFormData(boundary: String, audioData: Data) -> Data {
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
} 