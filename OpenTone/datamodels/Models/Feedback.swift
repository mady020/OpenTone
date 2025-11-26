
import Foundation


struct Feedback: Codable {
    let comments: String
    let rating: SessionFeedbackRating
    let wordsPerMinute: Double
    let durationInSeconds: Double
    let totalWords: Int
    let transcript: String
}
