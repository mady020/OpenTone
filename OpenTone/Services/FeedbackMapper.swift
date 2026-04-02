import Foundation

enum FeedbackMapper {

    static func toFeedback(_ response: SpeechAnalysisResponse) -> Feedback {
        UserDefaults.standard.set(response.progress.deltas.wpm, forKey: "opentone.lastWpmDelta")

        let mistakes: [SpeechMistake] = response.coaching.suggestions.prefix(5).map { suggestion in
            SpeechMistake(
                original: response.coaching.primaryIssueTitle,
                correction: suggestion,
                explanation: response.coaching.strengths.first ?? ""
            )
        }

        return Feedback(
            comments: response.coaching.strengths.first ?? "Keep practicing.",
            rating: rating(fluency: response.coaching.scores.fluency),
            wordsPerMinute: response.metrics.wpm,
            durationInSeconds: response.metrics.durationS,
            totalWords: response.metrics.totalWords,
            transcript: response.transcript,
            fillerWordCount: response.metrics.fillers,
            pauseCount: response.metrics.pauses,
            mistakes: mistakes,
            aiFeedbackSummary: response.progress.weeklySummary,
            coaching: response.coaching,
            progress: response.progress
        )
    }

    static func toSessionFeedback(_ response: SpeechAnalysisResponse, sessionId: UUID) -> SessionFeedback {
        let mispronouncedWords = response.coaching.evidence
            .filter { $0.type == "phoneme" }
            .compactMap { phonemeExpectedWord(from: $0.text) }

        return SessionFeedback(
            id: UUID().uuidString,
            sessionId: sessionId,
            fillerWordCount: response.metrics.fillers,
            mispronouncedWords: Array(Set(mispronouncedWords)).sorted(),
            fluencyScore: response.coaching.scores.fluency,
            onTopicScore: response.coaching.scores.clarity,
            confidenceScore: response.coaching.scores.confidence,
            clarityScore: response.coaching.scores.clarity,
            overallScore: response.coaching.scores.overall,
            pauses: response.metrics.pauses,
            summary: response.progress.weeklySummary,
            createdAt: Date()
        )
    }

    private static func phonemeExpectedWord(from evidence: String) -> String? {
        let parts = evidence.components(separatedBy: "->")
        guard parts.count >= 2 else { return nil }
        let rightPart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let expected: String
        if let parenIndex = rightPart.firstIndex(of: "(") {
            expected = String(rightPart[..<parenIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            expected = rightPart
        }
        return expected.isEmpty ? nil : expected
    }

    private static func rating(fluency: Double) -> SessionFeedbackRating {
        switch fluency {
        case 85...: return .excellent
        case 65...: return .good
        case 45...: return .average
        default: return .poor
        }
    }
}
