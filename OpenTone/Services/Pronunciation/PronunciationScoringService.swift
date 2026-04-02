import Foundation
import AVFoundation

/// Orchestrates the full pronunciation scoring pipeline:
/// text → phonemes → features → model → align → score → prosody → result
final class PronunciationScoringService {

    static let shared = PronunciationScoringService()

    private let textToPhoneme: TextToPhonemeService
    private let featureExtractor: AcousticFeatureExtractor
    private let acousticModel: AcousticModelProvider
    private let aligner: PhonemeAligner
    private let scorer: PhoneScoringEngine
    private let prosody: ProsodyAnalysisService
    private let transcription: SpeechTranscriptionService

    init(
        textToPhoneme: TextToPhonemeService? = nil,
        featureExtractor: AcousticFeatureExtractor? = nil,
        acousticModel: AcousticModelProvider? = nil,
        aligner: PhonemeAligner? = nil,
        scorer: PhoneScoringEngine? = nil,
        prosody: ProsodyAnalysisService? = nil,
        transcription: SpeechTranscriptionService? = nil
    ) {
        self.textToPhoneme = textToPhoneme ?? .shared
        self.featureExtractor = featureExtractor ?? AcousticFeatureExtractor()
        self.acousticModel = acousticModel ?? AcousticModelFactory.bestAvailable()
        self.aligner = aligner ?? PhonemeAligner()
        self.scorer = scorer ?? PhoneScoringEngine()
        self.prosody = prosody ?? ProsodyAnalysisService()
        self.transcription = transcription ?? .shared
    }

    // MARK: - Public API

    /// Run full pronunciation assessment on recorded audio against expected text.
    func assess(
        audioURL: URL,
        expectedText: String
    ) async throws -> PronunciationAssessmentResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 1. Convert expected text → phoneme sequence
        let (expectedSequence, variants) = textToPhoneme.convert(text: expectedText)

        guard !expectedSequence.isEmpty else {
            throw PronunciationError.emptyExpectedText
        }

        // 2. Load raw audio samples
        let samples = try loadAudioSamples(from: audioURL)

        guard samples.count > 1600 else {  // At least 0.1s at 16kHz
            throw PronunciationError.audioTooShort
        }

        // 3. Transcribe audio
        let transcriptionResult: TranscriptionResult
        do {
            transcriptionResult = try await transcription.transcribe(audioURL: audioURL)
        } catch {
            // Transcription failure is non-fatal for pronunciation scoring
            print("[PronunciationScoring] Transcription failed: \(error), continuing with assessment")
            transcriptionResult = TranscriptionResult(
                transcript: "",
                wordSegments: [],
                isFinal: true,
                source: "fallback"
            )
        }

        // 4. Extract acoustic features
        let features = featureExtractor.extractFeatures(from: samples)

        guard features.frameCount > 0 else {
            throw PronunciationError.featureExtractionFailed
        }

        // 5. Run acoustic model
        let posteriors = try await acousticModel.phonemePosteriors(features: features)

        // 6. Align expected phonemes to acoustic frames
        let alignment = aligner.align(
            expected: expectedSequence,
            posteriors: posteriors,
            variants: variants
        )

        // 7. Score each phone
        let phoneScores = scorer.score(
            alignment: alignment,
            expected: expectedSequence,
            posteriors: posteriors,
            variants: variants
        )

        // 8. Compute prosody
        let prosodyResult = prosody.analyze(
            samples: samples,
            expected: expectedSequence,
            wordTimings: transcriptionResult.wordSegments
        )

        // 9. Aggregate into word-level and overall scores
        let wordScores = buildWordScores(
            phoneScores: phoneScores,
            boundaries: expectedSequence.wordBoundaries
        )

        let overallScore = computeOverallScore(
            phoneScores: phoneScores,
            prosodyResult: prosodyResult
        )

        let processingTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        let diagnostics = PronunciationDiagnostics(
            expectedPhonemeCount: expectedSequence.count,
            alignedPhonemeCount: phoneScores.count,
            missingPhonemeCount: phoneScores.filter { $0.category == .missing }.count,
            substitutionCount: phoneScores.filter { $0.category == .substituted }.count,
            insertionCount: phoneScores.filter { $0.category == .inserted }.count,
            acceptableVariationCount: phoneScores.filter { $0.category == .acceptableVariation }.count,
            acousticModelUsed: acousticModel.modelName,
            processingTimeMs: processingTime
        )

        return PronunciationAssessmentResult(
            overallScore: overallScore,
            phoneScores: phoneScores,
            wordScores: wordScores,
            prosody: prosodyResult,
            expectedText: expectedText,
            transcribedText: transcriptionResult.transcript,
            diagnostics: diagnostics
        )
    }

    // MARK: - Audio Loading

    private func loadAudioSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0 else {
            throw PronunciationError.audioTooShort
        }

        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        let frameCapacity = max(1, AVAudioFrameCount(file.length))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw PronunciationError.featureExtractionFailed
        }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData else {
            throw PronunciationError.featureExtractionFailed
        }

        let frameLength = Int(buffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }

    // MARK: - Word Score Aggregation

    private func buildWordScores(
        phoneScores: [PhoneScore],
        boundaries: [WordPhoneBoundary]
    ) -> [WordPronunciationScore] {
        return boundaries.enumerated().map { wordIdx, boundary in
            let wordPhones = phoneScores.filter { $0.wordIndex == wordIdx }
            let avgScore: Float
            if wordPhones.isEmpty {
                avgScore = 70
            } else {
                avgScore = wordPhones.reduce(0) { $0 + $1.score } / Float(wordPhones.count)
            }

            let hasIssue = wordPhones.contains { $0.severity >= .moderate }
            let primaryIssue = wordPhones
                .filter { $0.severity >= .moderate }
                .sorted { $0.severity > $1.severity }
                .first?.diagnosticNote

            return WordPronunciationScore(
                word: boundary.word,
                wordIndex: wordIdx,
                score: avgScore,
                phoneScores: wordPhones,
                hasIssue: hasIssue,
                primaryIssue: primaryIssue
            )
        }
    }

    // MARK: - Overall Score

    private func computeOverallScore(
        phoneScores: [PhoneScore],
        prosodyResult: ProsodyResult
    ) -> Float {
        guard !phoneScores.isEmpty else { return 50 }

        // Weighted: 70% phoneme accuracy, 30% prosody (when reliable)
        let phonemeAvg = phoneScores.reduce(0) { $0 + $1.score } / Float(phoneScores.count)

        let prosodyWeight: Float
        switch prosodyResult.confidence {
        case .high: prosodyWeight = 0.30
        case .medium: prosodyWeight = 0.15
        case .low: prosodyWeight = 0.05
        }

        let phonemeWeight = 1.0 - prosodyWeight
        return phonemeAvg * phonemeWeight + prosodyResult.overallScore * prosodyWeight
    }
}

// MARK: - Errors

enum PronunciationError: LocalizedError {
    case emptyExpectedText
    case audioTooShort
    case featureExtractionFailed
    case assessmentFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyExpectedText: return "Expected text cannot be empty"
        case .audioTooShort: return "Audio recording is too short for analysis"
        case .featureExtractionFailed: return "Failed to extract acoustic features"
        case .assessmentFailed(let msg): return "Pronunciation assessment failed: \(msg)"
        }
    }
}
