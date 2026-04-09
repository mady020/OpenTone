import Foundation
import UIKit

struct UtteranceCorrection: Equatable {
    let originalFragment: String
    let correctedFragment: String
    let reason: String
}

final class UtteranceCorrectionService {
    static let shared = UtteranceCorrectionService()

    private struct GrammarRule {
        let pattern: String
        let replacement: String
        let reason: String
    }

    private let grammarRules: [GrammarRule] = [
        GrammarRule(pattern: "\\b[Ii]\\s+is\\b", replacement: "I am", reason: "subject_verb_agreement"),
        GrammarRule(pattern: "\\b[Ii]\\s+has\\b", replacement: "I have", reason: "subject_verb_agreement"),
        GrammarRule(pattern: "\\b(he|she|it)\\s+have\\b", replacement: "$1 has", reason: "subject_verb_agreement"),
        GrammarRule(pattern: "\\b(he|she|it)\\s+go\\b", replacement: "$1 goes", reason: "subject_verb_agreement"),
        GrammarRule(pattern: "\\b[Ii]\\s+goed\\b", replacement: "I went", reason: "irregular_verb"),
        GrammarRule(pattern: "\\bdidn['’]t\\s+went\\b", replacement: "didn't go", reason: "past_tense"),
        GrammarRule(pattern: "\\bmore\\s+better\\b", replacement: "better", reason: "comparative_form"),
        GrammarRule(pattern: "\\bthere\\s+is\\s+many\\b", replacement: "there are many", reason: "plural_agreement"),
        GrammarRule(pattern: "\\b(he|she|it)\\s+don['’]t\\b", replacement: "$1 doesn't", reason: "auxiliary_verb")
    ]

    private init() {}

    func firstCorrection(in utterance: String) -> UtteranceCorrection? {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let grammarCorrection = detectGrammarCorrection(in: trimmed) {
            return grammarCorrection
        }

        return detectSpellingCorrection(in: trimmed)
    }

    func correctionPrefix(for correction: UtteranceCorrection) -> String {
        "Small correction: say \"\(correction.correctedFragment)\" instead of \"\(correction.originalFragment)\"."
    }

    func applyCorrectionIfNeeded(userText: String, assistantText: String) -> String {
        let reply = assistantText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reply.isEmpty else { return assistantText }
        guard let correction = firstCorrection(in: userText) else { return assistantText }

        let lowerReply = reply.lowercased()
        if lowerReply.contains("small correction:") || lowerReply.contains("quick correction:") {
            return reply
        }

        let correctionLine = correctionPrefix(for: correction)
        return "\(correctionLine) \(reply)"
    }

    private func detectGrammarCorrection(in text: String) -> UtteranceCorrection? {
        for rule in grammarRules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(location: 0, length: (text as NSString).length)
            guard let match = regex.firstMatch(in: text, options: [], range: range) else {
                continue
            }

            let nsText = text as NSString
            let original = nsText.substring(with: match.range)
            let corrected = regex.stringByReplacingMatches(
                in: original,
                options: [],
                range: NSRange(location: 0, length: (original as NSString).length),
                withTemplate: rule.replacement
            )

            if original.caseInsensitiveCompare(corrected) != .orderedSame {
                return UtteranceCorrection(
                    originalFragment: original,
                    correctedFragment: corrected,
                    reason: rule.reason
                )
            }
        }

        return nil
    }

    private func detectSpellingCorrection(in text: String) -> UtteranceCorrection? {
        let checker = UITextChecker()
        let nsText = text as NSString
        var cursor = 0

        while cursor < nsText.length {
            let scanRange = NSRange(location: cursor, length: nsText.length - cursor)
            let misspelledRange = checker.rangeOfMisspelledWord(
                in: text,
                range: scanRange,
                startingAt: cursor,
                wrap: false,
                language: "en_US"
            )

            guard misspelledRange.location != NSNotFound else {
                break
            }

            cursor = misspelledRange.location + misspelledRange.length
            let token = nsText.substring(with: misspelledRange)

            if token.count < 3 { continue }
            if token.rangeOfCharacter(from: .decimalDigits) != nil { continue }
            if token.first?.isUppercase == true { continue }

            let guesses = checker.guesses(forWordRange: misspelledRange, in: text, language: "en_US") ?? []
            guard let bestGuess = guesses.first else { continue }
            guard token.caseInsensitiveCompare(bestGuess) != .orderedSame else { continue }

            return UtteranceCorrection(
                originalFragment: token,
                correctedFragment: bestGuess,
                reason: "spelling"
            )
        }

        return nil
    }
}
