import Foundation

struct SessionFeedback: Identifiable, Equatable, Codable {
    let id: String
    let sessionId: UUID
    let fillerWordCount: Int
    let mispronouncedWords: [String]
    let fluencyScore: Double   // 0.0—1.0
    let onTopicScore: Double   // 0.0—1.0
    let pauses: Int 
    let summary: String // transcript with mistakes
    let createdAt: Date
    
    static func ==(lhs: SessionFeedback, rhs: SessionFeedback) -> Bool {
        return lhs.id == rhs.id
    }
}
