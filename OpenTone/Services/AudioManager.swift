import Foundation
import Speech
import AVFAudio

final class AudioManager {

    static let shared = AudioManager()

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private(set) var isRecording = false
    private(set) var isMuted = false

    var onFinalTranscription: ((String) -> Void)?

    private init() {}

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted && isRecording {
            stopRecording()
        }
    }



    func requestPermissions(completion: @escaping (Bool) -> Void) {

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    completion(false)
                    return
                }

                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
        }
    }



    func startRecording() {

        guard !isRecording, !isMuted else { return }

        requestPermissions { [weak self] granted in
            guard let self, granted else {
                print("❌ Mic or Speech permission denied")
                return
            }

            self.beginRecording()
        }
    }

    private func beginRecording() {

        isRecording = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let input = audioEngine.inputNode

        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                print("🗣 LIVE:", text)

                if result.isFinal {
                    print("✅ FINAL:", text)
                    self.onFinalTranscription?(text)
                    self.cleanup()
                }
            }

            if error != nil {
                print("❌ Speech error:", error!)
                self.cleanup()
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        request?.endAudio()
    }

    private func cleanup() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request = nil
        task = nil
        isRecording = false
    }
}

