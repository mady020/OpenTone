import Foundation

/// Analyzes prosody (stress, rhythm, intonation) from acoustic features.
/// Uses duration, energy, and pitch to estimate stress patterns and delivery quality.
final class ProsodyAnalysisService {

    struct Config {
        var primaryStressEnergyThreshold: Float = 0.3    // dB above mean
        var primaryStressDurationThreshold: Float = 1.2  // ratio vs mean
        var pitchRangeMinHz: Float = 80
        var pitchRangeMaxHz: Float = 400
        var flatDeliveryPitchRangeThreshold: Float = 30  // Hz
        var minimumWordCount: Int = 3
    }

    private let config: Config
    private let featureExtractor: AcousticFeatureExtractor

    init(config: Config = Config(), featureExtractor: AcousticFeatureExtractor? = nil) {
        self.config = config
        self.featureExtractor = featureExtractor ?? AcousticFeatureExtractor()
    }

    // MARK: - Public API

    func analyze(
        samples: [Float],
        expected: PhonemeSequence,
        wordTimings: [TranscriptionWordSegment]
    ) -> ProsodyResult {
        guard expected.wordBoundaries.count >= config.minimumWordCount else {
            return ProsodyResult(
                overallScore: 70,
                confidence: .low,
                wordStress: [],
                issues: [ProsodyIssue(
                    type: .flatDelivery,
                    wordIndex: nil,
                    description: "Too few words for reliable prosody analysis",
                    severity: .none,
                    confidence: .low
                )]
            )
        }

        let energyContour = featureExtractor.extractEnergyContour(from: samples)
        let pitchContour = featureExtractor.extractPitchContour(from: samples)
        let sampleRate = 16000
        let hopLength = 160

        let wordStressResults = analyzeWordStress(
            expected: expected,
            wordTimings: wordTimings,
            energyContour: energyContour,
            pitchContour: pitchContour,
            sampleRate: sampleRate,
            hopLength: hopLength
        )

        let issues = detectProsodyIssues(
            wordStressResults: wordStressResults,
            energyContour: energyContour,
            pitchContour: pitchContour
        )

        let overallScore = computeOverallProsodyScore(
            wordStressResults: wordStressResults,
            issues: issues
        )

        return ProsodyResult(
            overallScore: overallScore,
            confidence: determineOverallConfidence(wordStressResults: wordStressResults),
            wordStress: wordStressResults,
            issues: issues
        )
    }

    // MARK: - Word-Level Stress Analysis

    private func analyzeWordStress(
        expected: PhonemeSequence,
        wordTimings: [TranscriptionWordSegment],
        energyContour: [Float],
        pitchContour: [Float?],
        sampleRate: Int,
        hopLength: Int
    ) -> [WordStressResult] {
        var results: [WordStressResult] = []

        for (wordIdx, boundary) in expected.wordBoundaries.enumerated() {
            let expectedStress = expected.phonesForWord(at: wordIdx)
                .map { $0.stress }
                .filter { $0 != .none }

            guard !expectedStress.isEmpty else { continue }

            // Find frame range for this word
            let (startFrame, endFrame) = wordFrameRange(
                wordIndex: wordIdx,
                wordTimings: wordTimings,
                totalFrames: energyContour.count,
                sampleRate: sampleRate,
                hopLength: hopLength,
                wordCount: expected.wordBoundaries.count
            )

            guard startFrame < endFrame, endFrame <= energyContour.count else { continue }

            let wordEnergy = Array(energyContour[startFrame..<endFrame])
            let wordPitch = Array(pitchContour[startFrame..<min(endFrame, pitchContour.count)])

            let observedStress = estimateStressFromAcoustics(
                energy: wordEnergy,
                pitch: wordPitch,
                expectedStress: expectedStress
            )

            let stressScore = compareStressPatterns(expected: expectedStress, observed: observedStress)
            let confidence: ScoreConfidence
            if wordEnergy.count >= 5 {
                confidence = .medium
            } else {
                confidence = .low
            }

            results.append(WordStressResult(
                word: boundary.word,
                wordIndex: wordIdx,
                expectedStressPattern: expectedStress,
                observedStressEstimate: observedStress,
                stressScore: stressScore,
                confidence: confidence
            ))
        }

        return results
    }

    private func wordFrameRange(
        wordIndex: Int,
        wordTimings: [TranscriptionWordSegment],
        totalFrames: Int,
        sampleRate: Int,
        hopLength: Int,
        wordCount: Int
    ) -> (Int, Int) {
        if wordIndex < wordTimings.count {
            let timing = wordTimings[wordIndex]
            let startFrame = Int(timing.startTime * Double(sampleRate) / Double(hopLength))
            let endFrame = Int(timing.endTime * Double(sampleRate) / Double(hopLength))
            return (max(0, startFrame), min(totalFrames, endFrame))
        }

        // Fallback: divide equally
        let framesPerWord = totalFrames / max(wordCount, 1)
        let start = wordIndex * framesPerWord
        let end = min(start + framesPerWord, totalFrames)
        return (start, end)
    }

    /// Estimate stress pattern from energy and pitch contours within a word.
    private func estimateStressFromAcoustics(
        energy: [Float],
        pitch: [Float?],
        expectedStress: [StressLevel]
    ) -> [StressLevel] {
        guard !energy.isEmpty else { return expectedStress }

        let syllableCount = expectedStress.count
        guard syllableCount > 0 else { return [] }

        // Divide frames into syllable-sized chunks
        let framesPerSyllable = max(1, energy.count / syllableCount)
        var observed: [StressLevel] = []

        let meanEnergy = energy.reduce(0, +) / Float(energy.count)

        for s in 0..<syllableCount {
            let start = s * framesPerSyllable
            let end = min(start + framesPerSyllable, energy.count)
            guard start < end else {
                observed.append(.unstressed)
                continue
            }

            let chunk = Array(energy[start..<end])
            let chunkMean = chunk.reduce(0, +) / Float(chunk.count)

            let pitchChunk = Array(pitch[start..<min(end, pitch.count)])
            let voicedPitch = pitchChunk.compactMap { $0 }
            let hasPitchRise = !voicedPitch.isEmpty &&
                (voicedPitch.max() ?? 0) - (voicedPitch.min() ?? 0) > 20

            // Estimate stress level
            let energyDelta = chunkMean - meanEnergy
            let durationRatio = Float(chunk.count) / Float(framesPerSyllable)

            if energyDelta > config.primaryStressEnergyThreshold || (hasPitchRise && durationRatio > 0.9) {
                observed.append(.primary)
            } else if energyDelta > config.primaryStressEnergyThreshold * 0.5 {
                observed.append(.secondary)
            } else {
                observed.append(.unstressed)
            }
        }

        return observed
    }

    /// Compare expected and observed stress patterns, returning a score 0-100.
    private func compareStressPatterns(expected: [StressLevel], observed: [StressLevel]) -> Float {
        guard !expected.isEmpty else { return 100 }

        let count = min(expected.count, observed.count)
        var matches: Float = 0
        var total: Float = 0

        for i in 0..<count {
            let exp = expected[i]
            let obs = observed[i]

            total += 1

            if exp == obs {
                matches += 1
            } else if exp == .primary && obs == .secondary {
                matches += 0.5    // Close enough
            } else if exp == .secondary && obs == .primary {
                matches += 0.7    // Overstressed but not terrible
            } else if exp == .unstressed && obs == .secondary {
                matches += 0.3    // Slight over-emphasis
            }
        }

        return total > 0 ? (matches / total) * 100 : 70
    }

    // MARK: - Issue Detection

    private func detectProsodyIssues(
        wordStressResults: [WordStressResult],
        energyContour: [Float],
        pitchContour: [Float?]
    ) -> [ProsodyIssue] {
        var issues: [ProsodyIssue] = []

        // Check for flat delivery (low pitch range)
        let voicedPitch = pitchContour.compactMap { $0 }
        if !voicedPitch.isEmpty {
            let pitchRange = (voicedPitch.max() ?? 0) - (voicedPitch.min() ?? 0)
            if pitchRange < config.flatDeliveryPitchRangeThreshold {
                issues.append(ProsodyIssue(
                    type: .flatDelivery,
                    wordIndex: nil,
                    description: "Pitch range is narrow, delivery may sound monotonous",
                    severity: .minor,
                    confidence: .medium
                ))
            }
        }

        // Check for weak primary stress
        for result in wordStressResults {
            let expectedPrimary = result.expectedStressPattern.contains(.primary)
            let observedPrimary = result.observedStressEstimate.contains(.primary)

            if expectedPrimary && !observedPrimary {
                issues.append(ProsodyIssue(
                    type: .weakStress,
                    wordIndex: result.wordIndex,
                    description: "Primary stress on '\(result.word)' may be weak",
                    severity: .minor,
                    confidence: result.confidence
                ))
            }
        }

        // Check for compressed stress (all syllables nearly equal energy)
        let stressScores = wordStressResults.map { $0.stressScore }
        if !stressScores.isEmpty {
            let meanScore = stressScores.reduce(0, +) / Float(stressScores.count)
            let variance = stressScores.map { ($0 - meanScore) * ($0 - meanScore) }.reduce(0, +) / Float(stressScores.count)
            if variance < 50 && meanScore < 60 {
                issues.append(ProsodyIssue(
                    type: .compressedStress,
                    wordIndex: nil,
                    description: "Stress pattern appears compressed — try emphasizing key syllables more",
                    severity: .moderate,
                    confidence: .low
                ))
            }
        }

        return issues
    }

    // MARK: - Overall Score

    private func computeOverallProsodyScore(
        wordStressResults: [WordStressResult],
        issues: [ProsodyIssue]
    ) -> Float {
        guard !wordStressResults.isEmpty else { return 70 }

        let avgStressScore = wordStressResults.reduce(0.0) { $0 + $1.stressScore } / Float(wordStressResults.count)

        // Penalize for detected issues (conservatively)
        var penalty: Float = 0
        for issue in issues {
            switch issue.severity {
            case .none: break
            case .minor: penalty += 3
            case .moderate: penalty += 7
            case .critical: penalty += 12
            }
        }

        return max(20, min(100, avgStressScore - penalty))
    }

    private func determineOverallConfidence(wordStressResults: [WordStressResult]) -> ScoreConfidence {
        let highConfCount = wordStressResults.filter { $0.confidence == .high }.count
        let total = wordStressResults.count
        guard total > 0 else { return .low }

        if highConfCount > total / 2 { return .high }
        if highConfCount > 0 { return .medium }
        return .low
    }
}
