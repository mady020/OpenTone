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

    private var usesEstimateOnlyPath: Bool {
        let modelName = acousticModel.modelName.lowercased()
        return modelName.contains("placeholder") || modelName.contains("heuristic")
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

        let hasSpeechEnergy = hasSpeechLikeEnergy(samples)

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

        if !hasSpeechEnergy && transcriptionResult.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PronunciationError.noSpeechDetected
        }

        let transcriptText = transcriptionResult.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcriptText.isEmpty {
            let matchScore = transcriptMatchScore(expected: expectedText, spoken: transcriptText)
            if matchScore < 0.30 {
                throw PronunciationError.offTargetSpeech
            }
        }

        // 4. Extract acoustic features
        if usesEstimateOnlyPath {
            let prosodyResult = prosody.analyze(
                samples: samples,
                expected: expectedSequence,
                wordTimings: transcriptionResult.wordSegments
            )

            let estimatedWordScores = buildTranscriptEstimateWordScores(
                boundaries: expectedSequence.wordBoundaries,
                spokenTranscript: transcriptText
            )

            let overallScore = computeEstimateOnlyOverallScore(
                wordScores: estimatedWordScores,
                prosodyResult: prosodyResult
            )

            let processingTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            let diagnostics = PronunciationDiagnostics(
                expectedPhonemeCount: expectedSequence.count,
                alignedPhonemeCount: 0,
                missingPhonemeCount: 0,
                substitutionCount: 0,
                insertionCount: 0,
                acceptableVariationCount: 0,
                acousticModelUsed: "\(acousticModel.modelName) (estimate-only)",
                processingTimeMs: processingTime
            )

            return PronunciationAssessmentResult(
                overallScore: overallScore,
                phoneScores: [],
                wordScores: estimatedWordScores,
                prosody: prosodyResult,
                expectedText: expectedText,
                transcribedText: transcriptionResult.transcript,
                diagnostics: diagnostics
            )
        }

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

    private func hasSpeechLikeEnergy(_ samples: [Float]) -> Bool {
        guard !samples.isEmpty else { return false }

        var sumSquares: Float = 0
        var peak: Float = 0
        for sample in samples {
            let absVal = abs(sample)
            sumSquares += sample * sample
            if absVal > peak {
                peak = absVal
            }
        }

        let rms = sqrt(sumSquares / Float(samples.count))

        let windowSize = 400 // 25ms @ 16kHz
        var activeWindows = 0
        var totalWindows = 0

        var idx = 0
        while idx < samples.count {
            let end = min(idx + windowSize, samples.count)
            let window = samples[idx..<end]
            let meanAbs = window.reduce(Float(0)) { $0 + abs($1) } / Float(max(window.count, 1))
            if meanAbs > 0.004 {
                activeWindows += 1
            }
            totalWindows += 1
            idx += windowSize
        }

        let activityRatio = totalWindows > 0 ? Float(activeWindows) / Float(totalWindows) : 0
        return peak > 0.015 || rms > 0.0035 || activityRatio > 0.06
    }

    private func transcriptMatchScore(expected: String, spoken: String) -> Float {
        let expectedWords = normalizedWordSet(from: expected)
        let spokenWords = normalizedWordSet(from: spoken)

        guard !expectedWords.isEmpty, !spokenWords.isEmpty else { return 0 }

        let overlap = expectedWords.intersection(spokenWords).count
        return Float(overlap) / Float(expectedWords.count)
    }

    private func normalizedWordSet(from text: String) -> Set<String> {
        let cleaned = text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)

        let words = cleaned
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        return Set(words)
    }

    private func buildTranscriptEstimateWordScores(
        boundaries: [WordPhoneBoundary],
        spokenTranscript: String
    ) -> [WordPronunciationScore] {
        let spokenWords = normalizedWords(from: spokenTranscript)

        var consumedIndices: Set<Int> = []

        return boundaries.enumerated().map { index, boundary in
            let targetWord = boundary.word
            let normalizedTarget = normalizeWord(targetWord)

            guard !normalizedTarget.isEmpty else {
                return WordPronunciationScore(
                    word: targetWord,
                    wordIndex: index,
                    score: 65,
                    phoneScores: [],
                    hasIssue: false,
                    primaryIssue: nil
                )
            }

            var bestMatchIndex: Int?
            var bestDistance = Int.max

            for (spokenIndex, spokenWord) in spokenWords.enumerated() where !consumedIndices.contains(spokenIndex) {
                let distance = editDistance(normalizedTarget, spokenWord)
                if distance < bestDistance {
                    bestDistance = distance
                    bestMatchIndex = spokenIndex
                }
                if distance == 0 {
                    break
                }
            }

            guard let matchIndex = bestMatchIndex else {
                return WordPronunciationScore(
                    word: targetWord,
                    wordIndex: index,
                    score: 38,
                    phoneScores: [],
                    hasIssue: true,
                    primaryIssue: "This word was not captured clearly. Try one slower repeat."
                )
            }

            consumedIndices.insert(matchIndex)
            let spokenWord = spokenWords[matchIndex]
            let length = max(normalizedTarget.count, spokenWord.count)
            let distanceRatio = length > 0 ? Float(bestDistance) / Float(length) : 1

            if distanceRatio == 0 {
                return WordPronunciationScore(
                    word: targetWord,
                    wordIndex: index,
                    score: 85,
                    phoneScores: [],
                    hasIssue: false,
                    primaryIssue: nil
                )
            }

            if distanceRatio <= 0.34 {
                return WordPronunciationScore(
                    word: targetWord,
                    wordIndex: index,
                    score: 67,
                    phoneScores: [],
                    hasIssue: true,
                    primaryIssue: "This word sounded close. Slow down and say each part clearly once."
                )
            }

            return WordPronunciationScore(
                word: targetWord,
                wordIndex: index,
                score: 48,
                phoneScores: [],
                hasIssue: true,
                primaryIssue: "This word did not match clearly. Listen once, then repeat slowly."
            )
        }
    }

    private func computeEstimateOnlyOverallScore(
        wordScores: [WordPronunciationScore],
        prosodyResult: ProsodyResult
    ) -> Float {
        let wordAverage: Float
        if wordScores.isEmpty {
            wordAverage = 55
        } else {
            wordAverage = wordScores.reduce(0) { $0 + $1.score } / Float(wordScores.count)
        }

        let prosodyWeight: Float
        switch prosodyResult.confidence {
        case .high: prosodyWeight = 0.20
        case .medium: prosodyWeight = 0.10
        case .low: prosodyWeight = 0.05
        }

        let wordWeight = 1.0 - prosodyWeight
        return (wordAverage * wordWeight) + (prosodyResult.overallScore * prosodyWeight)
    }

    private func normalizedWords(from text: String) -> [String] {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func normalizeWord(_ word: String) -> String {
        word
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }

    private func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)

        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var table = Array(
            repeating: Array(repeating: 0, count: b.count + 1),
            count: a.count + 1
        )

        for i in 0...a.count { table[i][0] = i }
        for j in 0...b.count { table[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    table[i][j] = table[i - 1][j - 1]
                } else {
                    table[i][j] = min(
                        table[i - 1][j] + 1,
                        table[i][j - 1] + 1,
                        table[i - 1][j - 1] + 1
                    )
                }
            }
        }

        return table[a.count][b.count]
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
    case noSpeechDetected
    case offTargetSpeech
    case microphoneAccessDenied
    case featureExtractionFailed
    case assessmentFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyExpectedText: return "Expected text cannot be empty"
        case .audioTooShort: return "Audio recording is too short for analysis"
        case .noSpeechDetected: return "We could not hear clear speech. Please speak a little louder and try again."
        case .offTargetSpeech: return "You read a different sentence. Please read the target phrase shown on screen."
        case .microphoneAccessDenied: return "Microphone access is unavailable. Please enable mic permission and try again."
        case .featureExtractionFailed: return "Failed to extract acoustic features"
        case .assessmentFailed(let msg): return "Pronunciation assessment failed: \(msg)"
        }
    }
}
