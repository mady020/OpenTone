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

    /// Active voice persona for the current utterance (set per speak() call)
    private var currentPersona: VoicePersona = .neutral

    private override init() {
        super.init()
        fallbackSynthesizer.delegate = self
    }

    func preload() async throws {
        try await loadModel()
    }

    /// `voiceName` is kept to avoid breaking old call sites.
    /// `volumeBoost` amplifies generated PCM before playback. Use values around 1.0...1.3.
    /// `persona` selects the voice character for the fallback AVSpeechSynthesizer path.
    func speak(text: String, voiceName: String = "default", volumeBoost: Float = 1.0, persona: VoicePersona = .neutral) async throws {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else {
            throw OnDeviceTTSError.emptyText
        }

        do {
            currentPersona = persona
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
            utterance.voice = VoiceSelector.bestVoice(for: currentPersona)
            utterance.rate = currentPersona.rate
            utterance.pitchMultiplier = currentPersona.pitch
            utterance.volume = 1.0
            utterance.preUtteranceDelay = 0.05
            utterance.postUtteranceDelay = 0.05
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

// MARK: - Voice Persona

/// Describes the voice character to use for TTS output.
/// Maps onto the best available system voice for each archetype.
enum VoicePersona {
    case neutral        // default narrator — balanced, clear
    case friendly       // warm, slightly bright — customer service, peer
    case professional   // neutral, measured — business, interviewer
    case authoritative  // deeper, steady — manager, announcer
    case casual         // relaxed pace — friend, barista
    case femaleNeutral  // female equivalent of neutral
    case femaleFriendly // warm female voice

    /// AVSpeechSynthesizer speaking rate. Default is AVSpeechUtteranceDefaultSpeechRate (~0.5)
    var rate: Float {
        switch self {
        case .neutral:        return 0.50
        case .friendly:       return 0.52
        case .professional:   return 0.47
        case .authoritative:  return 0.44
        case .casual:         return 0.54
        case .femaleNeutral:  return 0.50
        case .femaleFriendly: return 0.52
        }
    }

    /// Pitch multiplier: 0.5 (low) to 2.0 (high), default 1.0
    var pitch: Float {
        switch self {
        case .neutral:        return 1.00
        case .friendly:       return 1.05
        case .professional:   return 0.95
        case .authoritative:  return 0.88
        case .casual:         return 1.05
        case .femaleNeutral:  return 1.10
        case .femaleFriendly: return 1.15
        }
    }

    var prefersFemaleVoice: Bool {
        switch self {
        case .femaleNeutral, .femaleFriendly: return true
        default: return false
        }
    }

    // MARK: Scenario Category → Persona mapping

    static func forScenarioTitle(_ title: String) -> VoicePersona {
        let lower = title.lowercased()
        if lower.contains("interview") || lower.contains("manager") { return .authoritative }
        if lower.contains("doctor") || lower.contains("clinic") || lower.contains("hospital") { return .professional }
        if lower.contains("café") || lower.contains("cafe") || lower.contains("coffee") || lower.contains("restaurant") { return .casual }
        if lower.contains("bank") || lower.contains("office") || lower.contains("hotel") || lower.contains("reception") { return .professional }
        if lower.contains("friend") || lower.contains("party") || lower.contains("school") { return .friendly }
        if lower.contains("shop") || lower.contains("store") || lower.contains("market") { return .casual }
        return .neutral
    }
}

// MARK: - Voice Selector

/// Picks the best available AVSpeechSynthesisVoice on the current device.
/// Preference order: premium → enhanced → default, filtered by gender preference.
enum VoiceSelector {

    /// Returns the best available voice for the given persona.
    static func bestVoice(for persona: VoicePersona) -> AVSpeechSynthesisVoice? {
        let language = "en-US"
        let all = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }

        // Split by gender cue in identifier
        let female = all.filter { isFemaleVoice($0) }
        let male   = all.filter { !isFemaleVoice($0) }
        let pool   = persona.prefersFemaleVoice ? (female.isEmpty ? male : female)
                                                : (male.isEmpty   ? female : male)

        // Quality priority: premium > enhanced > (default)
        if #available(iOS 16.0, *) {
            if let premium = pool.first(where: { $0.quality == .premium }) {
                return premium
            }
            if let enhanced = pool.first(where: { $0.quality == .enhanced }) {
                return enhanced
            }
        }

        // Named fallbacks — these are the best sounding built-in voices
        let preferredNames: [String]
        if persona.prefersFemaleVoice {
            preferredNames = ["Samantha", "Karen", "Moira", "Tessa", "Veena"]
        } else {
            preferredNames = ["Daniel", "Alex", "Fred", "Tom", "Rishi"]
        }

        for name in preferredNames {
            if let match = all.first(where: { $0.name == name }) {
                return match
            }
        }

        // Last resort: language-matched default
        return pool.first ?? AVSpeechSynthesisVoice(language: language)
    }

    private static func isFemaleVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        // Check gender if available (iOS 17+)
        if #available(iOS 17.0, *) {
            return voice.gender == .female
        }
        // Fallback: name-based heuristic
        let femaleNames = ["Samantha", "Karen", "Moira", "Tessa", "Veena",
                           "Victoria", "Allison", "Ava", "Susan", "Zoe",
                           "Fiona", "Siri (Female)", "Helena", "Laura"]
        return femaleNames.contains(voice.name)
    }
}

