
import Foundation


struct Feedback: Codable {
    let comments: String
    let rating: SessionFeedbackRating
    let wordsPerMinute: Double
    let durationInSeconds: Double
    let totalWords: Int
    let transcript: String

    var fillerWordCount: Int?
    var pauseCount: Int?
    var mistakes: [SpeechMistake]?
    var aiFeedbackSummary: String?
}

struct SpeechMistake: Codable {
    let original: String
    let correction: String
    let explanation: String   
}
