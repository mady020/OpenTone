
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
}

struct SpeechMistake: Codable {
    let original: String      // What the user said
    let correction: String    // What they should have said
    let explanation: String   // Why it's wrong / tip
}
