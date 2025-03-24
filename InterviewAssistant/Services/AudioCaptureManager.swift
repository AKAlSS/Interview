import AVFoundation
import Combine
import Foundation

class AudioCaptureManager {
    private var audioEngine: AVAudioEngine
    private var audioBuffer = [Float]()
    private let apiKey: String
    
    // Use Combine to publish transcript updates
    private let transcriptSubject = PassthroughSubject<String, Never>()
    var transcriptPublisher: AnyPublisher<String, Never> {
        return transcriptSubject.eraseToAnyPublisher()
    }
    
    init(apiKey: String = "") {
        self.apiKey = apiKey
        audioEngine = AVAudioEngine()
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
        #if os(macOS)
        // For macOS, check available audio devices
        let devices = AVCaptureDevice.devices(for: .audio)
        for device in devices {
            print("Available audio device: \(device.localizedName)")
        }
        #endif
        
        // Note: For full implementation, provide instructions to user for:
        // 1. Installing BlackHole virtual audio driver
        // 2. Configuring macOS audio to route system audio through BlackHole
        // 3. Selecting BlackHole as input device for the app
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
            
            // Transcribe using Whisper API
            transcribeWithWhisper(audioData: audioData)
            
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
    
    private func transcribeWithWhisper(audioData: Data) {
        guard !apiKey.isEmpty else {
            print("API key not provided for Whisper transcription")
            return
        }
        
        // Convert PCM data to WAV format
        let wavData = createWavFile(from: audioData, sampleRate: 16000)
        
        // Create a temporary file for the audio data
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("audio_chunk.wav")
        
        do {
            try wavData.write(to: tempFileURL)
            
            // Prepare the upload task
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let boundary = UUID().uuidString
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Create multipart form data
            let httpBody = createMultipartFormData(
                boundary: boundary,
                fileURL: tempFileURL,
                fileName: "audio.wav",
                modelName: "whisper-1"
            )
            
            request.httpBody = httpBody
            
            // Create and start the task
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                // Clean up the temporary file
                try? FileManager.default.removeItem(at: tempFileURL)
                
                if let error = error {
                    print("Error during Whisper API request: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received from Whisper API")
                    return
                }
                
                do {
                    // Parse JSON response
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let transcript = json["text"] as? String {
                        // Send the transcript via the publisher
                        DispatchQueue.main.async {
                            self?.transcriptSubject.send(transcript)
                        }
                    } else {
                        print("Failed to parse Whisper API response")
                        print("Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
                    }
                } catch {
                    print("Error parsing Whisper API response: \(error.localizedDescription)")
                }
            }
            
            task.resume()
        } catch {
            print("Error writing audio data to temporary file: \(error.localizedDescription)")
        }
    }
    
    private func createWavFile(from pcmData: Data, sampleRate: Int) -> Data {
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!) // ChunkID
        var fileSize: UInt32 = UInt32(36 + pcmData.count) // ChunkSize
        wavData.append(withUnsafeBytes(of: &fileSize) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!) // Format
        
        // fmt subchunk
        wavData.append("fmt ".data(using: .ascii)!) // Subchunk1ID
        var subchunk1Size: UInt32 = 16 // Subchunk1Size (PCM)
        wavData.append(withUnsafeBytes(of: &subchunk1Size) { Data($0) })
        var audioFormat: UInt16 = 1 // AudioFormat (PCM)
        wavData.append(withUnsafeBytes(of: &audioFormat) { Data($0) })
        var numChannels: UInt16 = 1 // NumChannels (mono)
        wavData.append(withUnsafeBytes(of: &numChannels) { Data($0) })
        var sampleRateValue: UInt32 = UInt32(sampleRate)
        wavData.append(withUnsafeBytes(of: &sampleRateValue) { Data($0) })
        var byteRate: UInt32 = UInt32(sampleRate * 2) // ByteRate = SampleRate * NumChannels * BitsPerSample/8
        wavData.append(withUnsafeBytes(of: &byteRate) { Data($0) })
        var blockAlign: UInt16 = 2 // BlockAlign = NumChannels * BitsPerSample/8
        wavData.append(withUnsafeBytes(of: &blockAlign) { Data($0) })
        var bitsPerSample: UInt16 = 16 // BitsPerSample
        wavData.append(withUnsafeBytes(of: &bitsPerSample) { Data($0) })
        
        // data subchunk
        wavData.append("data".data(using: .ascii)!) // Subchunk2ID
        var subchunk2Size: UInt32 = UInt32(pcmData.count) // Subchunk2Size
        wavData.append(withUnsafeBytes(of: &subchunk2Size) { Data($0) })
        
        // The actual audio data
        wavData.append(pcmData)
        
        return wavData
    }
    
    private func createMultipartFormData(boundary: String, fileURL: URL, fileName: String, modelName: String) -> Data {
        var body = Data()
        
        // Model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(modelName)\r\n".data(using: .utf8)!)
        
        // File field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        // File data
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        }
        
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // For testing purposes - simulates a transcript without actual audio capture
    func simulateTranscript(_ text: String) {
        transcriptSubject.send(text)
    }
} 