import Foundation
import AVFoundation
import Speech

// MARK: - Transcription Result

struct TranscriptionWordSegment: Codable {
    let word: String
    let startTime: Double
    let endTime: Double
    let confidence: Float
}

struct TranscriptionResult {
    let transcript: String
    let wordSegments: [TranscriptionWordSegment]
    let isFinal: Bool
    let source: String
}

// MARK: - Protocol

protocol TranscriptionProvider {
    var name: String { get }
    func transcribe(audioURL: URL) async throws -> TranscriptionResult
}

// MARK: - Whisper Provider (wraps existing AudioManager)

final class WhisperTranscriptionProvider: TranscriptionProvider {
    let name = "Whisper"

    func transcribe(audioURL: URL) async throws -> TranscriptionResult {
        let text: String? = await withCheckedContinuation { continuation in
            AudioManager.shared.transcribeFile(at: audioURL) { text in
                continuation.resume(returning: text)
            }
        }

        guard let transcript = text, !transcript.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        // Whisper C API doesn't provide word-level timing by default
        // Estimate word timing from total duration
        let duration = try audioDuration(url: audioURL)
        let words = transcript.split(separator: " ").map(String.init)
        let segments = estimateWordTimings(words: words, totalDuration: duration)

        return TranscriptionResult(
            transcript: transcript,
            wordSegments: segments,
            isFinal: true,
            source: "whisper"
        )
    }

    private func audioDuration(url: URL) throws -> Double {
        let file = try AVAudioFile(forReading: url)
        return Double(file.length) / file.fileFormat.sampleRate
    }

    private func estimateWordTimings(words: [String], totalDuration: Double) -> [TranscriptionWordSegment] {
        guard !words.isEmpty else { return [] }
        let avgDuration = totalDuration / Double(words.count)
        return words.enumerated().map { i, word in
            TranscriptionWordSegment(
                word: word,
                startTime: Double(i) * avgDuration,
                endTime: Double(i + 1) * avgDuration,
                confidence: 0.8   // Whisper doesn't expose per-word confidence
            )
        }
    }
}

// MARK: - Apple Speech Provider

/// Uses SFSpeechRecognizer for word-level timing and confidence metadata.
/// Primarily used as a secondary source to enrich Whisper transcription.
final class AppleSpeechTranscriptionProvider: TranscriptionProvider {
    let name = "AppleSpeech"

    private let recognizer: SFSpeechRecognizer?

    init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    var isAvailable: Bool {
        recognizer?.isAvailable ?? false
    }

    func transcribe(audioURL: URL) async throws -> TranscriptionResult {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false

            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let transcript = result.bestTranscription
                let segments = transcript.segments.map { segment in
                    TranscriptionWordSegment(
                        word: segment.substring,
                        startTime: segment.timestamp,
                        endTime: segment.timestamp + segment.duration,
                        confidence: segment.confidence
                    )
                }

                continuation.resume(returning: TranscriptionResult(
                    transcript: transcript.formattedString,
                    wordSegments: segments,
                    isFinal: true,
                    source: "apple_speech"
                ))
            }
        }
    }
}

// MARK: - Transcription Service Coordinator

/// Coordinates multiple transcription providers.
/// Uses Whisper as primary, optionally enriches with Apple Speech word timing.
final class SpeechTranscriptionService {

    static let shared = SpeechTranscriptionService()

    private let primaryProvider: TranscriptionProvider
    private let secondaryProvider: TranscriptionProvider?

    init(
        primary: TranscriptionProvider? = nil,
        secondary: TranscriptionProvider? = nil
    ) {
        self.primaryProvider = primary ?? WhisperTranscriptionProvider()
        self.secondaryProvider = secondary ?? {
            let apple = AppleSpeechTranscriptionProvider()
            return apple.isAvailable ? apple : nil
        }()
    }

    /// Transcribe audio, preferring primary (Whisper) and enriching with secondary (Apple) timing.
    func transcribe(audioURL: URL, enrichWithTiming: Bool = true) async throws -> TranscriptionResult {
        let primaryResult = try await primaryProvider.transcribe(audioURL: audioURL)

        guard enrichWithTiming, let secondary = secondaryProvider else {
            return primaryResult
        }

        // Try to get word-level timing from Apple Speech
        do {
            let secondaryResult = try await secondary.transcribe(audioURL: audioURL)
            return mergeResults(primary: primaryResult, secondary: secondaryResult)
        } catch {
            // Apple Speech failed — return primary as-is
            print("[Transcription] Secondary provider failed: \(error.localizedDescription)")
            return primaryResult
        }
    }

    /// Merge Whisper transcript with Apple Speech word timing.
    private func mergeResults(primary: TranscriptionResult, secondary: TranscriptionResult) -> TranscriptionResult {
        // Use primary transcript text, but try to adopt secondary's word timing
        let primaryWords = primary.transcript.split(separator: " ").map { $0.lowercased() }
        let secondarySegments = secondary.wordSegments

        var enrichedSegments: [TranscriptionWordSegment] = []
        var secondaryIdx = 0

        for (i, word) in primaryWords.enumerated() {
            // Try to find matching word in secondary segments
            var matchedSegment: TranscriptionWordSegment?
            while secondaryIdx < secondarySegments.count {
                let secWord = secondarySegments[secondaryIdx].word.lowercased()
                if secWord == word {
                    matchedSegment = secondarySegments[secondaryIdx]
                    secondaryIdx += 1
                    break
                } else {
                    secondaryIdx += 1
                }
            }

            if let matched = matchedSegment {
                enrichedSegments.append(TranscriptionWordSegment(
                    word: String(primaryWords[i]),
                    startTime: matched.startTime,
                    endTime: matched.endTime,
                    confidence: matched.confidence
                ))
            } else {
                // Keep estimated timing from primary
                if i < primary.wordSegments.count {
                    enrichedSegments.append(primary.wordSegments[i])
                }
            }
        }

        return TranscriptionResult(
            transcript: primary.transcript,
            wordSegments: enrichedSegments.isEmpty ? primary.wordSegments : enrichedSegments,
            isFinal: true,
            source: "whisper+apple_timing"
        )
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case emptyResult
    case recognizerUnavailable
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyResult: return "Transcription produced no text"
        case .recognizerUnavailable: return "Speech recognizer is not available"
        case .recognitionFailed(let msg): return "Recognition failed: \(msg)"
        }
    }
}
