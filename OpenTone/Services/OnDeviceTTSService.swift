import Foundation
import AVFoundation
import os.log

final class OnDeviceTTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = OnDeviceTTSService()

    private let logger = Logger(subsystem: "com.sudosquad.OpenTone", category: "TTS")
    private let synthesisQueue = DispatchQueue(label: "com.sudosquad.opentone.localtts", qos: .userInitiated)

    private var tts: TTSService?
    private var modelLoadingTask: Task<Void, Error>?

    private var currentAudioPlayer: AVAudioPlayer?
    private var currentPlaybackContinuation: CheckedContinuation<Void, Never>?

    private var fallbackPlaybackContinuation: CheckedContinuation<Void, Never>?
    private let fallbackSynthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        fallbackSynthesizer.delegate = self
    }

    func preload() async throws {
        try await loadModel()
    }

    /// `voiceName` is kept to avoid breaking old call sites.
    /// `volumeBoost` amplifies generated PCM before playback. Use values around 1.0...1.3.
    func speak(text: String, voiceName: String = "default", volumeBoost: Float = 1.0) async throws {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else {
            throw OnDeviceTTSError.emptyText
        }

        do {
            try await loadModel()
            let voice = mapVoice(voiceName)
            let audioURL = try await synthesizeToFile(text: cleanedText, voice: voice, volumeBoost: volumeBoost)
            logger.info("On-device synthesized file: \(audioURL.path, privacy: .public)")
            try await playAudioFile(audioURL)
            logger.info("On-device playback finished")
        } catch {
            logger.error("On-device synthesis failed, falling back to AVSpeechSynthesizer: \(error.localizedDescription, privacy: .public)")
            print("OnDeviceTTSService: local synthesis failed -> \(error.localizedDescription)")
            try await speakWithSystemFallback(cleanedText)
        }
    }

    func stopPlaying() {
        Task { @MainActor in
            currentPlaybackContinuation?.resume()
            currentPlaybackContinuation = nil
            currentAudioPlayer?.stop()
            currentAudioPlayer = nil

            if fallbackSynthesizer.isSpeaking {
                fallbackSynthesizer.stopSpeaking(at: .immediate)
            }
            fallbackPlaybackContinuation?.resume()
            fallbackPlaybackContinuation = nil

            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func loadModel() async throws {
        if tts != nil {
            return
        }

        if let task = modelLoadingTask {
            try await task.value
            return
        }

        let task = Task<Void, Error> { [weak self] in
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self?.synthesisQueue.async { [weak self] in
                    guard let self else {
                        continuation.resume(throwing: OnDeviceTTSError.deallocated)
                        return
                    }

                    if self.tts != nil {
                        continuation.resume()
                        return
                    }

                    do {
                        self.tts = try TTSService()
                        self.logger.info("Local TTS engine initialized")
                        continuation.resume()
                    } catch {
                        self.logger.error("Local TTS engine init failed: \(error.localizedDescription, privacy: .public)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        modelLoadingTask = task

        do {
            try await task.value
        } catch {
            modelLoadingTask = nil
            throw error
        }
    }

    private func synthesizeToFile(text: String, voice: TTSService.Voice, volumeBoost: Float) async throws -> URL {
        guard let tts else {
            throw OnDeviceTTSError.engineNotInitialized
        }

        return try await tts.synthesize(text: text, nfe: 5, voice: voice, language: .en, volumeBoost: volumeBoost)
    }

    private func configurePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }

    private func playAudioFile(_ fileURL: URL) async throws {
        try await MainActor.run {
            try configurePlaybackSession()

            currentPlaybackContinuation?.resume()
            currentPlaybackContinuation = nil
            currentAudioPlayer?.stop()

            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.prepareToPlay()
            currentAudioPlayer = player
            player.play()
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                self.currentPlaybackContinuation = continuation
                let duration = max(self.currentAudioPlayer?.duration ?? 0.0, 0.05)
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) { [weak self] in
                    guard let self else { return }
                    self.currentPlaybackContinuation?.resume()
                    self.currentPlaybackContinuation = nil
                    self.currentAudioPlayer = nil
                }
            }
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    @MainActor
    private func speakWithSystemFallback(_ text: String) async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)

        if fallbackSynthesizer.isSpeaking {
            fallbackSynthesizer.stopSpeaking(at: .immediate)
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            fallbackPlaybackContinuation?.resume()
            fallbackPlaybackContinuation = continuation

            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.48
            utterance.volume = 1.0
            fallbackSynthesizer.speak(utterance)
        }

        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        fallbackPlaybackContinuation?.resume()
        fallbackPlaybackContinuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        fallbackPlaybackContinuation?.resume()
        fallbackPlaybackContinuation = nil
    }

    private func mapVoice(_ voiceName: String) -> TTSService.Voice {
        let normalized = voiceName.lowercased()
        if normalized.contains("female") || normalized.hasPrefix("f") {
            return .female
        }
        return .male
    }
}

enum OnDeviceTTSError: LocalizedError {
    case emptyText
    case engineNotInitialized
    case deallocated

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Cannot synthesize empty text."
        case .engineNotInitialized:
            return "Local TTS engine is not initialized."
        case .deallocated:
            return "OnDeviceTTSService was deallocated unexpectedly."
        }
    }
}
