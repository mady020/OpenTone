
import Foundation


struct Feedback: Codable {
    let comments: String
    let rating: SessionFeedbackRating
    let wordsPerMinute: Double
    let durationInSeconds: Double
    let totalWords: Int
    let transcript: String

    /// Filler words detected (e.g. "um", "uh", "like")
    var fillerWordCount: Int?
    /// Estimated number of pauses (> 1 second gap)
    var pauseCount: Int?
    /// Specific mistakes / suggestions from AI analysis
    var mistakes: [SpeechMistake]?
    /// Overall AI-generated summary of the user's performance
    var aiFeedbackSummary: String?

    // MARK: - Speech Coach additions (from BackendSpeechService)

    /// Full structured coaching from the deterministic backend
    var coaching: SpeechCoaching?
    /// Progress deltas vs. previous session
    var progress: SpeechProgress?

    /// Overall coaching score 0–100 derived from backend scores
    var overallScore: Double? {
        guard let c = coaching else { return nil }
        return (c.scores.fluency + c.scores.confidence + c.scores.clarity) / 3.0
    }

    /// Human-readable today's focus pulled from coaching primary issue
    var todaysFocus: String? {
        coaching?.primaryIssueTitle
    }
}

struct SpeechMistake: Codable {
    let original: String      // What the user said / issue label
    let correction: String    // Concrete suggestion
    let explanation: String   // Strength or context
}
