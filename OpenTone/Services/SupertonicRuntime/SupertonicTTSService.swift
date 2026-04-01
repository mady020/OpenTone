import Foundation
import AVFoundation
import AVFAudio

final class TTSService {
    enum Voice { case male, female }
    enum Language: String, CaseIterable {
        case en = "en"
        case ko = "ko"
        case es = "es"
        case pt = "pt"
        case fr = "fr"
        
        var displayName: String {
            switch self {
            case .en: return "English"
            case .ko: return "한국어"
            case .es: return "Español"
            case .pt: return "Português"
            case .fr: return "Français"
            }
        }
    }

    init() throws {}

    // `nfe` is intentionally kept for API compatibility with existing call sites.
    func synthesize(text: String, nfe: Int, voice: Voice, language: Language, volumeBoost: Float = 1.0) async throws -> URL {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw NSError(
                domain: "TTS",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot synthesize empty text."]
            )
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = bestVoice(for: language, requestedVoice: voice) ?? AVSpeechSynthesisVoice(language: language.rawValue)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = min(1.0, max(0.2, volumeBoost))

        return try await renderToAudioFile(utterance)
    }

    @MainActor
    private func renderToAudioFile(_ utterance: AVSpeechUtterance) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("apple_tts_\(UUID().uuidString)")
            .appendingPathExtension("caf")

        let synthesizer = AVSpeechSynthesizer()
        var audioFile: AVAudioFile?
        var hasFrames = false
        var didResume = false

        return try await withCheckedThrowingContinuation { continuation in
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }

                if pcmBuffer.frameLength == 0 {
                    guard !didResume else { return }
                    didResume = true
                    if hasFrames {
                        continuation.resume(returning: outputURL)
                    } else {
                        continuation.resume(
                            throwing: NSError(
                                domain: "TTS",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "No audio was produced by AVSpeechSynthesizer."]
                            )
                        )
                    }
                    return
                }

                do {
                    if audioFile == nil {
                        audioFile = try AVAudioFile(
                            forWriting: outputURL,
                            settings: pcmBuffer.format.settings,
                            commonFormat: pcmBuffer.format.commonFormat,
                            interleaved: pcmBuffer.format.isInterleaved
                        )
                    }
                    try audioFile?.write(from: pcmBuffer)
                    hasFrames = true
                } catch {
                    guard !didResume else { return }
                    didResume = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func bestVoice(for language: Language, requestedVoice: Voice) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().hasPrefix(language.rawValue.lowercased())
        }

        guard !candidates.isEmpty else {
            return AVSpeechSynthesisVoice(language: language.rawValue)
        }

        return candidates.sorted { lhs, rhs in
            let lScore = qualityScore(for: lhs) * 100 + preferenceScore(for: lhs, requestedVoice: requestedVoice)
            let rScore = qualityScore(for: rhs) * 100 + preferenceScore(for: rhs, requestedVoice: requestedVoice)
            if lScore == rScore {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lScore > rScore
        }.first
    }

    private func qualityScore(for voice: AVSpeechSynthesisVoice) -> Int {
        switch voice.quality {
        case .premium:
            return 3
        case .enhanced:
            return 2
        default:
            return 1
        }
    }

    private func preferenceScore(for voice: AVSpeechSynthesisVoice, requestedVoice: Voice) -> Int {
        let name = voice.name.lowercased()
        let maleHints = ["alex", "daniel", "fred", "jorge", "tom", "arthur", "male"]
        let femaleHints = ["ava", "samantha", "karen", "allison", "victoria", "female"]

        switch requestedVoice {
        case .male:
            return maleHints.contains(where: { name.contains($0) }) ? 20 : 0
        case .female:
            return femaleHints.contains(where: { name.contains($0) }) ? 20 : 0
        }
    }
}
