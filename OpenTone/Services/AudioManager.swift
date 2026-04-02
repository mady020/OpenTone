import Foundation
import AVFAudio
import whisper

final class AudioManager {

    static let shared = AudioManager()
    
    private let audioEngine = AVAudioEngine()
    private var whisperContext: OpaquePointer?
    private var hasInputTapInstalled = false
    private var isStartRecordingPending = false

    // MARK: - File Recording (for backend /analyze upload)

    private var audioRecorder: AVAudioRecorder?
    /// URL of the most recently completed recording file. Available after stopRecording().
    private(set) var lastRecordingURL: URL?

    private(set) var isRecording = false {
        didSet {
            onRecordingStateChanged?(isRecording)
        }
    }
    private(set) var isMuted = false
    private var currentTranscription: String = ""

    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    var onFinalTranscription: ((String) -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?

    private init() {
        Task {
            do {
                print("Loading Whisper model...")
                // In production, you'd download this model or bundle it with the app.
                // For demonstration, downloading the tiny model if it doesn't exist
                let modelURL = try await getModelURL()
                
                // Initialize whisper context directly from C API
                var params = whisper_context_default_params()
                self.whisperContext = modelURL.path.withCString { path in
                    return whisper_init_from_file_with_params(path, params)
                }
                
                if self.whisperContext != nil {
                    print("Whisper loaded successfully")
                } else {
                    print("❌ Failed to load Whisper context")
                }
            } catch {
                print("❌ Failed to load Whisper: \(error)")
            }
        }
    }
    
    private func getModelURL() async throws -> URL {
        let fileManager = FileManager.default
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelURL = documentURL.appendingPathComponent("ggml-tiny.en.bin")
        
        if fileManager.fileExists(atPath: modelURL.path) {
            return modelURL
        }
        
        let url = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin")!
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: modelURL)
        return modelURL
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted && isRecording {
            stopRecording()
        }
    }



    func requestPermissions(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }



    func startRecording(completion: ((Bool) -> Void)? = nil) {
        guard !isRecording, !isStartRecordingPending else {
            completion?(false)
            return
        }
        isStartRecordingPending = true

        requestPermissions { [weak self] granted in
            guard let self else { return }
            self.isStartRecordingPending = false

            guard granted else {
                print("❌ Mic or Speech permission denied")
                completion?(false)
                return
            }

            let started = self.beginRecording()
            completion?(started)
        }
    }

    private func beginRecording() -> Bool {

        guard !isRecording else { return true }

        currentTranscription = ""
        lastRecordingURL = nil

        let session = AVAudioSession.sharedInstance()
        // Use playAndRecord so callers (like AICallController) don't need to switch
        // categories between recording and playback — avoids audio session conflicts.
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Failed to activate audio session: \(error.localizedDescription)")
            return false
        }

        // Setup tap for amplitude tracking if needed by callers, 
        // otherwise just let AVAudioRecorder do everything
        let input = audioEngine.inputNode
        if hasInputTapInstalled {
            input.removeTap(onBus: 0)
            hasInputTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            self?.onAudioBuffer?(buffer)
        }
        hasInputTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
            cleanup()
            return false
        }

        // --- AVAudioRecorder parallel file recording ---

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        // Whisper requires 16kHz WAV format natively without conversions for simplicity
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        guard let recorder = try? AVAudioRecorder(url: tmpURL, settings: settings) else {
            print("❌ Failed to create AVAudioRecorder")
            cleanup()
            return false
        }

        guard recorder.record() else {
            print("❌ Failed to start AVAudioRecorder")
            cleanup()
            return false
        }

        audioRecorder = recorder
        isRecording = true
        return true
    }

    func stopRecording(autoTranscribe: Bool = true) {
        guard isRecording else { return }
        isRecording = false

        // Finalise the file recording
        audioRecorder?.stop()
        lastRecordingURL = audioRecorder?.url
        audioRecorder = nil

        cleanup()

        // Transcribe on-device using SwiftWhisper
        if autoTranscribe, let url = lastRecordingURL,
           let onFinal = onFinalTranscription {
            transcribeFile(at: url) { text in
                onFinal(text ?? "")
            }
        }
    }
    
    // Make the transcription capability available globally
    func transcribeFile(at url: URL, completion: @escaping (String?) -> Void) {
        Task {
            guard let context = self.whisperContext else {
                print("❌ Whisper is not initialized yet")
                await MainActor.run { completion(nil) }
                return
            }
            
            do {
                print("Transcribing on-device...")
                
                // Read PCM frames from the WAV file
                let file = try AVAudioFile(forReading: url)
                guard file.length > 0 else {
                    await MainActor.run { completion(nil) }
                    return
                }

                guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
                    await MainActor.run { completion(nil) }
                    return
                }

                let frameCapacity = max(1, AVAudioFrameCount(file.length))
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
                    await MainActor.run { completion(nil) }
                    return
                }
                
                try file.read(into: buffer)
                guard let floatChannelData = buffer.floatChannelData else {
                    await MainActor.run { completion(nil) }
                    return
                }
                
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else {
                    await MainActor.run { completion(nil) }
                    return
                }

                let floats = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
                
                // Use C API directly as the wrapper is minimal
                var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
                params.print_progress = false
                params.print_timestamps = false
                params.print_special = false
                params.translate = false
                params.language = "en".withCString { UnsafePointer($0) }
                params.n_threads = 4
                
                let result = floats.withUnsafeBufferPointer { ptr -> Int32 in
                    guard let baseAddress = ptr.baseAddress else { return -1 }
                    return whisper_full(context, params, baseAddress, Int32(floats.count))
                }
                
                if result != 0 {
                    print("❌ Whisper transcription failed with code: \(result)")
                    await MainActor.run { completion(nil) }
                    return
                }
                
                let n_segments = whisper_full_n_segments(context)
                var resultText = ""
                
                for i in 0..<n_segments {
                    if let cString = whisper_full_get_segment_text(context, i) {
                        resultText += String(cString: cString)
                    }
                }
                
                let text = resultText.trimmingCharacters(in: .whitespacesAndNewlines)
                print("On-device transcription: \(text)")
                await MainActor.run {
                    completion(text)
                }
            } catch {
                print("❌ Whisper transcription error:", error)
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }

    private func cleanup() {
        if audioEngine.isRunning {
             audioEngine.stop()
        }
        if hasInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTapInstalled = false
        }
    }

    // MARK: - Pronunciation Pipeline Support

    /// Extract raw 16kHz float32 PCM samples from the last recording for acoustic analysis.
    func rawPCMSamplesFromLastRecording() async -> [Float]? {
        guard let url = lastRecordingURL else { return nil }
        return try? loadPCMSamples(from: url)
    }

    /// Load PCM samples from any WAV file URL.
    func loadPCMSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0 else { return [] }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else { return [] }

        let frameCapacity = max(1, AVAudioFrameCount(file.length))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            return []
        }

        try file.read(into: buffer)
        guard let channelData = buffer.floatChannelData else { return [] }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return [] }

        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }

    func resetForLogout() {
        if isRecording {
            stopRecording(autoTranscribe: false)
        } else {
            cleanup()
        }

        audioRecorder = nil
        lastRecordingURL = nil
        currentTranscription = ""
        isMuted = false
        isStartRecordingPending = false

        onAudioBuffer = nil
        onFinalTranscription = nil
        onRecordingStateChanged = nil
    }
}

