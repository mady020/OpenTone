import Foundation

/// Performs forced alignment between expected phoneme sequences and acoustic posteriors
/// using Dynamic Time Warping (DTW).
final class PhonemeAligner {

    struct Config {
        var insertionPenalty: Float = 2.0
        var deletionPenalty: Float = 3.0
        var substitutionPenalty: Float = 1.5
        var minFramesPerPhone: Int = 2
        var maxFramesPerPhone: Int = 50
    }

    private let config: Config

    init(config: Config = Config()) {
        self.config = config
    }

    // MARK: - Public API

    /// Align expected phoneme sequence to acoustic posterior frames.
    func align(
        expected: PhonemeSequence,
        posteriors: PhonePosteriorMatrix,
        variants: [PhonemeVariant] = []
    ) -> AlignmentResult {
        let N = expected.count      // expected phones
        let T = posteriors.frameCount // acoustic frames

        guard N > 0, T > 0 else {
            return AlignmentResult(alignedPhones: [], overallScore: 0, alignmentPath: [])
        }

        // DTW cost matrix: cost[i][t] = cost of aligning phone i to frame t
        var cost = [[Float]](repeating: [Float](repeating: Float.infinity, count: T + 1), count: N + 1)
        var backtrack = [[(Int, Int, AlignmentCategory)]](
            repeating: [(Int, Int, AlignmentCategory)](repeating: (0, 0, .matched), count: T + 1),
            count: N + 1
        )

        cost[0][0] = 0

        // Initialize first row (deletions of frames)
        for t in 1...T {
            cost[0][t] = cost[0][t - 1] + config.insertionPenalty
            backtrack[0][t] = (0, t - 1, .inserted)
        }

        // Initialize first column (missing phones)
        for i in 1...N {
            cost[i][0] = cost[i - 1][0] + config.deletionPenalty
            backtrack[i][0] = (i - 1, 0, .missing)
        }

        // Fill DTW matrix
        for i in 1...N {
            let expectedPhone = expected.phones[i - 1]
            for t in 1...T {
                let posterior = posteriors.posteriorForPhone(expectedPhone.phone, atFrame: t - 1)
                let matchCost = -log(max(posterior, 1e-10))

                // Check acceptable variants
                let variantCost = bestVariantCost(
                    wordPhoneIndex: i - 1,
                    expected: expected,
                    variants: variants,
                    posteriors: posteriors,
                    frame: t - 1
                )
                let effectiveMatchCost = min(matchCost, variantCost)

                // Match/substitute: phone i aligned to frame t
                let matchTotal = cost[i - 1][t - 1] + effectiveMatchCost
                // Skip phone (missing): phone i has no acoustic evidence
                let skipPhone = cost[i - 1][t] + config.deletionPenalty
                // Skip frame (insertion/expansion): frame t not consumed by new phone
                let skipFrame = cost[i][t - 1] + min(effectiveMatchCost * 0.1, config.insertionPenalty * 0.3)

                if matchTotal <= skipPhone && matchTotal <= skipFrame {
                    cost[i][t] = matchTotal
                    let cat: AlignmentCategory = posterior > 0.1 ? .matched : .substituted
                    backtrack[i][t] = (i - 1, t - 1, cat)
                } else if skipPhone <= skipFrame {
                    cost[i][t] = skipPhone
                    backtrack[i][t] = (i - 1, t, .missing)
                } else {
                    cost[i][t] = skipFrame
                    backtrack[i][t] = (i, t - 1, .inserted)
                }
            }
        }

        // Backtrace to find alignment path
        let (alignedPhones, path) = backtrace(
            backtrack: backtrack,
            expected: expected,
            posteriors: posteriors,
            cost: cost,
            N: N,
            T: T
        )

        let totalCost = cost[N][T]
        let maxPossibleCost = Float(N) * config.deletionPenalty + Float(T) * config.insertionPenalty
        let normalizedScore = max(0, min(100, (1.0 - totalCost / max(maxPossibleCost, 1)) * 100))

        return AlignmentResult(
            alignedPhones: alignedPhones,
            overallScore: normalizedScore,
            alignmentPath: path
        )
    }

    // MARK: - Backtrace

    private func backtrace(
        backtrack: [[(Int, Int, AlignmentCategory)]],
        expected: PhonemeSequence,
        posteriors: PhonePosteriorMatrix,
        cost: [[Float]],
        N: Int,
        T: Int
    ) -> ([AlignedPhone], [AlignmentStep]) {
        var i = N
        var t = T
        var rawPath: [(Int, Int, AlignmentCategory)] = []

        while i > 0 || t > 0 {
            let (prevI, prevT, category) = backtrack[i][t]
            rawPath.append((i, t, category))
            i = prevI
            t = prevT
        }

        rawPath.reverse()

        // Group consecutive frames per phone
        var phoneFrameMap: [Int: (startFrame: Int, endFrame: Int, category: AlignmentCategory)] = [:]
        var alignmentSteps: [AlignmentStep] = []

        for (phoneIdx, frameIdx, category) in rawPath {
            guard phoneIdx > 0, phoneIdx <= N else { continue }
            let pIdx = phoneIdx - 1
            let fIdx = max(0, frameIdx - 1)

            if let existing = phoneFrameMap[pIdx] {
                phoneFrameMap[pIdx] = (existing.startFrame, fIdx, existing.category)
            } else {
                phoneFrameMap[pIdx] = (fIdx, fIdx, category)
            }

            alignmentSteps.append(AlignmentStep(
                expectedIndex: pIdx,
                frameIndex: fIdx,
                cost: cost[phoneIdx][frameIdx],
                operation: category
            ))
        }

        // Build aligned phones
        var alignedPhones: [AlignedPhone] = []

        for pIdx in 0..<N {
            let expectedPhone = expected.phones[pIdx]
            let wordIndex = findWordIndex(phoneIndex: pIdx, boundaries: expected.wordBoundaries)

            if let mapping = phoneFrameMap[pIdx] {
                let confidence = averagePosterior(
                    phone: expectedPhone.phone,
                    startFrame: mapping.startFrame,
                    endFrame: mapping.endFrame,
                    posteriors: posteriors
                )

                alignedPhones.append(AlignedPhone(
                    expectedPhone: expectedPhone,
                    startFrame: mapping.startFrame,
                    endFrame: mapping.endFrame,
                    confidence: confidence,
                    durationFrames: mapping.endFrame - mapping.startFrame + 1,
                    category: mapping.category,
                    wordIndex: wordIndex
                ))
            } else {
                // Phone not found in alignment — missing
                alignedPhones.append(AlignedPhone(
                    expectedPhone: expectedPhone,
                    startFrame: 0,
                    endFrame: 0,
                    confidence: 0,
                    durationFrames: 0,
                    category: .missing,
                    wordIndex: wordIndex
                ))
            }
        }

        return (alignedPhones, alignmentSteps)
    }

    // MARK: - Helpers

    private func bestVariantCost(
        wordPhoneIndex: Int,
        expected: PhonemeSequence,
        variants: [PhonemeVariant],
        posteriors: PhonePosteriorMatrix,
        frame: Int
    ) -> Float {
        let wordIdx = findWordIndex(phoneIndex: wordPhoneIndex, boundaries: expected.wordBoundaries)
        guard wordIdx < expected.wordBoundaries.count else { return Float.infinity }

        let boundary = expected.wordBoundaries[wordIdx]
        let localIdx = wordPhoneIndex - boundary.startIndex

        var bestCost = Float.infinity

        for variant in variants {
            guard variant.word.lowercased() == boundary.word.lowercased() else { continue }
            for alternate in variant.alternates {
                guard localIdx < alternate.count else { continue }
                let altPhone = alternate[localIdx].phone
                let posterior = posteriors.posteriorForPhone(altPhone, atFrame: frame)
                let cost = -log(max(posterior, 1e-10))
                bestCost = min(bestCost, cost)
            }
        }

        return bestCost
    }

    private func findWordIndex(phoneIndex: Int, boundaries: [WordPhoneBoundary]) -> Int {
        for (i, boundary) in boundaries.enumerated() {
            if phoneIndex >= boundary.startIndex &&
               phoneIndex < boundary.startIndex + boundary.length {
                return i
            }
        }
        return 0
    }

    private func averagePosterior(
        phone: ARPAPhone,
        startFrame: Int,
        endFrame: Int,
        posteriors: PhonePosteriorMatrix
    ) -> Float {
        guard startFrame <= endFrame else { return 0 }
        var sum: Float = 0
        let count = endFrame - startFrame + 1
        for f in startFrame...endFrame {
            sum += posteriors.posteriorForPhone(phone, atFrame: f)
        }
        return sum / Float(count)
    }
}
