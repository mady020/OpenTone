import Foundation

/// Converts raw alignment results into per-phone scores with variation suppression.
final class PhoneScoringEngine {

    // MARK: - Acceptable Variation Rules

    /// Phone pairs that should not be penalized in casual American English.
    private let acceptableSubstitutions: Set<PhonePairKey> = {
        var pairs = Set<PhonePairKey>()
        // T-flapping: /T/ → /D/ intervocalically
        pairs.insert(PhonePairKey(.T, .D))
        // Rhotic variation: /ER/ ↔ /AH/
        pairs.insert(PhonePairKey(.ER, .AH))
        // Weak vowel reduction
        pairs.insert(PhonePairKey(.IH, .AH))
        pairs.insert(PhonePairKey(.EH, .AH))
        pairs.insert(PhonePairKey(.UH, .AH))
        pairs.insert(PhonePairKey(.AO, .AA))
        // /IY/ ↔ /IH/ in unstressed syllables
        pairs.insert(PhonePairKey(.IY, .IH))
        // /AE/ ↔ /EH/ pre-nasal (pen-pin merger region)
        pairs.insert(PhonePairKey(.AE, .EH))
        // Cot-caught merger
        pairs.insert(PhonePairKey(.AA, .AO))
        return pairs
    }()

    /// Phones that are commonly deleted in fast speech without loss of intelligibility.
    private let commonlyDeletedPhones: Set<ARPAPhone> = [
        .T, .D,     // Final stop deletion
        .HH,        // H-dropping in unstressed function words
    ]

    // MARK: - Public API

    func score(
        alignment: AlignmentResult,
        expected: PhonemeSequence,
        posteriors: PhonePosteriorMatrix,
        variants: [PhonemeVariant]
    ) -> [PhoneScore] {
        return alignment.alignedPhones.map { aligned in
            scorePhone(
                aligned: aligned,
                expected: expected,
                posteriors: posteriors,
                variants: variants
            )
        }
    }

    // MARK: - Per-Phone Scoring

    private func scorePhone(
        aligned: AlignedPhone,
        expected: PhonemeSequence,
        posteriors: PhonePosteriorMatrix,
        variants: [PhonemeVariant]
    ) -> PhoneScore {
        let wordIndex = aligned.wordIndex
        let word = wordIndex < expected.wordBoundaries.count
            ? expected.wordBoundaries[wordIndex].word
            : ""

        switch aligned.category {
        case .matched:
            return scoreMatchedPhone(aligned: aligned, posteriors: posteriors, word: word)

        case .substituted:
            return scoreSubstitutedPhone(
                aligned: aligned,
                posteriors: posteriors,
                expected: expected,
                variants: variants,
                word: word
            )

        case .missing:
            return scoreMissingPhone(aligned: aligned, word: word)

        case .inserted:
            return PhoneScore(
                phone: aligned.expectedPhone,
                score: 60,
                category: .inserted,
                severity: .minor,
                confidence: .low,
                wordIndex: wordIndex,
                word: word,
                substitutedWith: nil,
                diagnosticNote: "Extra phone detected in audio"
            )
        }
    }

    private func scoreMatchedPhone(
        aligned: AlignedPhone,
        posteriors: PhonePosteriorMatrix,
        word: String
    ) -> PhoneScore {
        let confidence = aligned.confidence
        let rawScore = confidence * 100

        // Duration check — very short phones may be underarticulated
        let durationPenalty: Float
        if aligned.durationFrames < 2 {
            durationPenalty = 15
        } else if aligned.durationFrames < 3 {
            durationPenalty = 5
        } else {
            durationPenalty = 0
        }

        let score = max(0, min(100, rawScore - durationPenalty))

        let severity: ScoreSeverity
        let category: PhoneScoreCategory

        if score >= 70 {
            severity = .none
            category = .correct
        } else if score >= 50 {
            severity = .minor
            category = .weak
        } else {
            severity = .moderate
            category = .weak
        }

        let scoreConfidence: ScoreConfidence = confidence > 0.3 ? .high : (confidence > 0.1 ? .medium : .low)

        return PhoneScore(
            phone: aligned.expectedPhone,
            score: score,
            category: category,
            severity: severity,
            confidence: scoreConfidence,
            wordIndex: aligned.wordIndex,
            word: word,
            substitutedWith: nil,
            diagnosticNote: nil
        )
    }

    private func scoreSubstitutedPhone(
        aligned: AlignedPhone,
        posteriors: PhonePosteriorMatrix,
        expected: PhonemeSequence,
        variants: [PhonemeVariant],
        word: String
    ) -> PhoneScore {
        // Find what the model actually heard
        let midFrame = aligned.startFrame + aligned.durationFrames / 2
        let (actualPhone, actualProb) = posteriors.bestPhone(atFrame: min(midFrame, posteriors.frameCount - 1))

        // Check if this substitution is an acceptable variation
        let pairKey = PhonePairKey(aligned.expectedPhone.phone, actualPhone)
        let isAcceptableVariation = acceptableSubstitutions.contains(pairKey)

        // Check if unstressed vowel reduction should be tolerated
        let isUnstressedReduction = aligned.expectedPhone.phone.isVowel
            && aligned.expectedPhone.stress == .unstressed
            && actualPhone == .AH

        // Check explicit variants from dictionary
        let isInVariants = checkVariantMatch(
            phone: actualPhone,
            aligned: aligned,
            expected: expected,
            variants: variants
        )

        if isAcceptableVariation || isUnstressedReduction || isInVariants {
            return PhoneScore(
                phone: aligned.expectedPhone,
                score: 80,
                category: .acceptableVariation,
                severity: .none,
                confidence: .medium,
                wordIndex: aligned.wordIndex,
                word: word,
                substitutedWith: actualPhone,
                diagnosticNote: "Acceptable variant: /\(aligned.expectedPhone.phone.ipaSymbol)/ → /\(actualPhone.ipaSymbol)/"
            )
        }

        // Real substitution — score based on acoustic evidence
        let score = max(10, min(60, actualProb * 80))
        let severity: ScoreSeverity = score < 30 ? .critical : .moderate

        return PhoneScore(
            phone: aligned.expectedPhone,
            score: score,
            category: .substituted,
            severity: severity,
            confidence: actualProb > 0.2 ? .high : .medium,
            wordIndex: aligned.wordIndex,
            word: word,
            substitutedWith: actualPhone,
            diagnosticNote: "Substitution: expected /\(aligned.expectedPhone.phone.ipaSymbol)/, heard /\(actualPhone.ipaSymbol)/"
        )
    }

    private func scoreMissingPhone(
        aligned: AlignedPhone,
        word: String
    ) -> PhoneScore {
        let phone = aligned.expectedPhone.phone

        // Common deletions in casual speech
        if commonlyDeletedPhones.contains(phone) {
            return PhoneScore(
                phone: aligned.expectedPhone,
                score: 65,
                category: .acceptableVariation,
                severity: .none,
                confidence: .medium,
                wordIndex: aligned.wordIndex,
                word: word,
                substitutedWith: nil,
                diagnosticNote: "Common deletion of /\(phone.ipaSymbol)/ in casual speech"
            )
        }

        // Truly missing phone
        let severity: ScoreSeverity = phone.isVowel ? .critical : .moderate

        return PhoneScore(
            phone: aligned.expectedPhone,
            score: 10,
            category: .missing,
            severity: severity,
            confidence: .high,
            wordIndex: aligned.wordIndex,
            word: word,
            substitutedWith: nil,
            diagnosticNote: "Phone /\(phone.ipaSymbol)/ not detected in audio"
        )
    }

    // MARK: - Variant Check

    private func checkVariantMatch(
        phone: ARPAPhone,
        aligned: AlignedPhone,
        expected: PhonemeSequence,
        variants: [PhonemeVariant]
    ) -> Bool {
        let wordIdx = aligned.wordIndex
        guard wordIdx < expected.wordBoundaries.count else { return false }
        let boundary = expected.wordBoundaries[wordIdx]
        let localIdx = findLocalIndex(aligned: aligned, boundary: boundary, expected: expected)

        for variant in variants {
            guard variant.word.lowercased() == boundary.word.lowercased() else { continue }
            for alternate in variant.alternates {
                guard localIdx < alternate.count else { continue }
                if alternate[localIdx].phone == phone {
                    return true
                }
            }
        }
        return false
    }

    private func findLocalIndex(
        aligned: AlignedPhone,
        boundary: WordPhoneBoundary,
        expected: PhonemeSequence
    ) -> Int {
        // Find this phone's position within its word
        for i in 0..<expected.count {
            if expected.phones[i].phone == aligned.expectedPhone.phone
                && i >= boundary.startIndex
                && i < boundary.startIndex + boundary.length {
                return i - boundary.startIndex
            }
        }
        return 0
    }
}

// MARK: - Phone Pair Key

private struct PhonePairKey: Hashable {
    let a: ARPAPhone
    let b: ARPAPhone

    init(_ a: ARPAPhone, _ b: ARPAPhone) {
        // Order-independent
        if a.rawValue <= b.rawValue {
            self.a = a
            self.b = b
        } else {
            self.a = b
            self.b = a
        }
    }
}
