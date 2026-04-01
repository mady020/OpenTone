import Foundation
import NaturalLanguage

final class AppleIntelligenceAICallProvider: AICallLLMProvider {

    let id: AICallProviderID = .appleIntelligence

    func isAvailable() -> Bool {
        true
    }

    func startSession(_ input: AICallStartInput) async throws -> AICallStartResult {
        let opener = "Hi, I am your on-device conversation coach. Let's practice \(input.scenario.lowercased()) together. What would you like to talk about first?"
        return AICallStartResult(assistantText: opener, provider: id)
    }

    func generateTurn(_ input: AICallTurnInput) async throws -> AICallTurnResult {
        let cleaned = input.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = buildResponse(for: cleaned, scenario: input.scenario, difficulty: input.difficulty)
        let correctedResponse = UtteranceCorrectionService.shared.applyCorrectionIfNeeded(
            userText: cleaned,
            assistantText: response
        )

        return AICallTurnResult(
            userTranscript: cleaned,
            assistantText: correctedResponse,
            metrics: nil,
            provider: id
        )
    }

    private func buildResponse(for text: String, scenario: String, difficulty: String) -> String {
        if text.isEmpty {
            return "I did not catch that. Could you repeat that in one clear sentence?"
        }

        let isQuestion = text.contains("?")
        let keyTerms = extractKeyTerms(from: text)
        let anchor = keyTerms.first ?? "that"

        let acknowledgement: String
        if isQuestion {
            acknowledgement = "Good question about \(anchor)."
        } else {
            acknowledgement = "That is a clear point, especially about \(anchor)."
        }

        let followUp: String
        switch difficulty.lowercased() {
        case "hard":
            followUp = "Can you explain your reasoning in two connected sentences and give one concrete example?"
        case "easy":
            followUp = "Can you add one more detail using a simple sentence?"
        default:
            followUp = "What happened next, and why was it important in this situation?"
        }

        if scenario.lowercased().contains("interview") {
            return "\(acknowledgement) Please answer like an interview response: situation, action, and result."
        }

        return "\(acknowledgement) \(followUp)"
    }

    private func extractKeyTerms(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var nouns: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            guard let tag, tag == .noun else { return true }
            let token = String(text[tokenRange]).lowercased()
            if token.count >= 3 && !Self.stopWords.contains(token) {
                nouns.append(token)
            }
            return nouns.count < 4
        }

        if nouns.isEmpty {
            nouns = text
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 4 && !Self.stopWords.contains($0) }
        }

        return Array(NSOrderedSet(array: nouns)) as? [String] ?? []
    }

    private static let stopWords: Set<String> = [
        "this", "that", "with", "from", "have", "your", "about", "there", "would", "could", "should", "because", "really", "very"
    ]
}
