import Foundation
import CoreML

struct PronunciationInsight: Hashable {
    let observedFragment: String
    let expectedFragment: String
    let phonemeHint: String
    let coachingTip: String
}

final class OnDevicePronunciationAnalyzer {
    static let shared = OnDevicePronunciationAnalyzer()

    private lazy var classifierModel: MLModel? = Self.loadBundledModel()

    private init() {}

    func analyze(transcript: String) -> [PronunciationInsight] {
        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        var insights: [PronunciationInsight] = []

        if let correction = UtteranceCorrectionService.shared.firstCorrection(in: cleaned),
           let inferred = inferPhonemeInsight(observed: correction.originalFragment, expected: correction.correctedFragment) {
            insights.append(inferred)
        }

        let tokens = tokenize(cleaned)
        for token in tokens {
            guard let known = knownConfusions[token] else { continue }
            insights.append(known)
        }

        var unique: [PronunciationInsight] = []
        var seen: Set<String> = []
        for insight in insights {
            let key = "\(insight.observedFragment.lowercased())>\(insight.expectedFragment.lowercased())"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(insight)
            }
        }

        let ranked = rankWithCoreMLIfAvailable(unique)
        return Array(ranked.prefix(3))
    }

    func evidenceItems(from insights: [PronunciationInsight]) -> [EvidenceItem] {
        insights.map { insight in
            EvidenceItem(
                type: "phoneme",
                timestamp: 0,
                text: "\(insight.observedFragment) -> \(insight.expectedFragment) (\(insight.phonemeHint))"
            )
        }
    }

    func suggestions(from insights: [PronunciationInsight]) -> [String] {
        insights.map { insight in
            "\(insight.phonemeHint): \(insight.coachingTip)"
        }
    }

    private func inferPhonemeInsight(observed: String, expected: String) -> PronunciationInsight? {
        let o = observed.lowercased()
        let e = expected.lowercased()

        if (o.contains("v") && e.contains("w")) || (o.contains("w") && e.contains("v")) {
            return PronunciationInsight(
                observedFragment: observed,
                expectedFragment: expected,
                phonemeHint: "/v/ and /w/",
                coachingTip: "Touch your lower lip to upper teeth for /v/ and keep both lips rounded for /w/."
            )
        }

        if (o.contains("l") && e.contains("r")) || (o.contains("r") && e.contains("l")) {
            return PronunciationInsight(
                observedFragment: observed,
                expectedFragment: expected,
                phonemeHint: "/l/ and /r/",
                coachingTip: "For /l/, touch the tongue tip to the alveolar ridge; for /r/, keep the tongue lifted without touching."
            )
        }

        if e.contains("th") || o.contains("th") {
            return PronunciationInsight(
                observedFragment: observed,
                expectedFragment: expected,
                phonemeHint: "/th/",
                coachingTip: "Place the tongue lightly between the teeth and release air gently for /th/."
            )
        }

        if hasStrongVowelShift(observed: o, expected: e) {
            return PronunciationInsight(
                observedFragment: observed,
                expectedFragment: expected,
                phonemeHint: "vowel contrast",
                coachingTip: "Stretch stressed vowels slightly and keep short vowels quick to improve contrast."
            )
        }

        return nil
    }

    private func hasStrongVowelShift(observed: String, expected: String) -> Bool {
        let vowels = CharacterSet(charactersIn: "aeiou")
        let observedVowels = observed.unicodeScalars
            .filter { vowels.contains($0) }
            .map { String($0) }
        let expectedVowels = expected.unicodeScalars
            .filter { vowels.contains($0) }
            .map { String($0) }
        return !observedVowels.isEmpty && !expectedVowels.isEmpty && observedVowels != expectedVowels
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func rankWithCoreMLIfAvailable(_ insights: [PronunciationInsight]) -> [PronunciationInsight] {
        guard let model = classifierModel else {
            return insights.sorted {
                heuristicScore(for: $0) > heuristicScore(for: $1)
            }
        }

        return insights.sorted {
            modelScore(for: $0, model: model) > modelScore(for: $1, model: model)
        }
    }

    private func modelScore(for insight: PronunciationInsight, model: MLModel) -> Double {
        let inputValues: [String: MLFeatureValue] = [
            "observed": MLFeatureValue(string: insight.observedFragment.lowercased()),
            "expected": MLFeatureValue(string: insight.expectedFragment.lowercased()),
            "hint": MLFeatureValue(string: insight.phonemeHint.lowercased()),
            "distance": MLFeatureValue(double: normalizedEditDistance(a: insight.observedFragment, b: insight.expectedFragment))
        ]

        guard let provider = try? MLDictionaryFeatureProvider(dictionary: inputValues),
              let prediction = try? model.prediction(from: provider) else {
            return heuristicScore(for: insight)
        }

        if let confidence = prediction.featureValue(for: "confidence")?.doubleValue {
            return confidence
        }

        if let score = prediction.featureValue(for: "score")?.doubleValue {
            return score
        }

        return heuristicScore(for: insight)
    }

    private func heuristicScore(for insight: PronunciationInsight) -> Double {
        1.0 - normalizedEditDistance(a: insight.observedFragment, b: insight.expectedFragment)
    }

    private func normalizedEditDistance(a: String, b: String) -> Double {
        let aChars = Array(a.lowercased())
        let bChars = Array(b.lowercased())

        if aChars.isEmpty && bChars.isEmpty { return 0 }

        var dp = Array(repeating: Array(repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }

        if !aChars.isEmpty && !bChars.isEmpty {
            for i in 1...aChars.count {
                for j in 1...bChars.count {
                    if aChars[i - 1] == bChars[j - 1] {
                        dp[i][j] = dp[i - 1][j - 1]
                    } else {
                        dp[i][j] = min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]) + 1
                    }
                }
            }
        }

        let distance = Double(dp[aChars.count][bChars.count])
        let denom = Double(max(aChars.count, bChars.count))
        return denom > 0 ? distance / denom : 0
    }

    private static func loadBundledModel() -> MLModel? {
        let bundle = Bundle.main
        let candidates = [
            "PronunciationPhoneClassifier",
            "PhonemeFeedbackClassifier",
            "OnDevicePronunciationClassifier"
        ]

        for name in candidates {
            guard let url = bundle.url(forResource: name, withExtension: "mlmodelc") else { continue }
            guard let model = try? MLModel(contentsOf: url) else { continue }
            return model
        }

        return nil
    }

    private let knownConfusions: [String: PronunciationInsight] = [
        "tink": PronunciationInsight(
            observedFragment: "tink",
            expectedFragment: "think",
            phonemeHint: "/th/",
            coachingTip: "For /th/, move the tongue forward between the teeth instead of using /t/."
        ),
        "dis": PronunciationInsight(
            observedFragment: "dis",
            expectedFragment: "this",
            phonemeHint: "/th/",
            coachingTip: "Voice the /th/ sound in \"this\" by adding gentle vocal fold vibration."
        ),
        "bery": PronunciationInsight(
            observedFragment: "bery",
            expectedFragment: "very",
            phonemeHint: "/v/",
            coachingTip: "For /v/, keep the lower lip touching the upper teeth while voicing."
        )
    ]
}
