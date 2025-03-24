import AVFoundation
import Combine

class AudioCaptureManager {
    private var audioEngine: AVAudioEngine
    private var audioBuffer = [Float]()
    private var whisperClient: WhisperClient
    
    // Use Combine to publish transcript updates
    private let transcriptSubject = PassthroughSubject<String, Never>()
    var transcriptPublisher: AnyPublisher<String, Never> {
        return transcriptSubject.eraseToAnyPublisher()
    }
    
    init() {
        audioEngine = AVAudioEngine()
        whisperClient = WhisperClient(apiKey: "your-openai-api-key")
        setupAudioSession()
    }
    
    func startCapturing() {
        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Process audio buffer in chunks
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, time in
                // Convert buffer to samples
                let channelData = buffer.floatChannelData?[0]
                if let channelData = channelData {
                    let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
                    self?.processAudioSamples(samples)
                }
            }
            
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopCapturing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func setupAudioSession() {
        // For macOS, we need to configure system audio capture
        // This typically requires BlackHole virtual audio driver
        // In a real implementation, we would provide setup instructions
        
        // Note: This is a simplification. In practice, you need to:
        // 1. Install BlackHole virtual audio driver
        // 2. Configure macOS audio to route system audio through BlackHole
        // 3. Select BlackHole as input device for the app
    }
    
    private func processAudioSamples(_ samples: [Float]) {
        // Append new samples to buffer
        audioBuffer.append(contentsOf: samples)
        
        // Process in 5-second chunks with 2.5-second overlap as per specs
        let sampleRate = 16000 // 16kHz as per specs
        let chunkSize = 5 * sampleRate
        let overlapSize = Int(2.5 * Double(sampleRate))
        
        if audioBuffer.count >= chunkSize {
            // Extract chunk for processing
            let chunk = Array(audioBuffer.prefix(chunkSize))
            
            // Convert to audio data format for Whisper
            let audioData = convertSamplesToAudioData(chunk)
            
            // Transcribe using Whisper
            whisperClient.transcribe(audioData: audioData) { [weak self] transcript in
                if let transcript = transcript, !transcript.isEmpty {
                    self?.transcriptSubject.send(transcript)
                }
            }
            
            // Keep overlap for next chunk
            if audioBuffer.count > overlapSize {
                audioBuffer.removeFirst(audioBuffer.count - overlapSize)
            }
        }
    }
    
    private func convertSamplesToAudioData(_ samples: [Float]) -> Data {
        // Convert float samples to 16-bit PCM
        var pcmData = Data(capacity: samples.count * 2)
        
        for sample in samples {
            // Convert normalized float to Int16
            let intSample = Int16(sample * 32767.0)
            pcmData.append(contentsOf: withUnsafeBytes(of: intSample) { Array($0) })
        }
        
        return pcmData
    }
    
    func simulateTranscript(_ text: String) {
        // For testing - simulates a transcript from audio
        transcriptSubject.send(text)
    }
}

// Simple Whisper API client
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
        
        let httpBody = createFormData(boundary: boundary, audioData: audioData)
        request.httpBody = httpBody
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
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
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func createFormData(boundary: String, audioData: Data) -> Data {
        var formData = Data()
        
        // Add model parameter
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        formData.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add audio file
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        formData.append(audioData)
        formData.append("\r\n".data(using: .utf8)!)
        
        // Final boundary
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return formData
    }
} 