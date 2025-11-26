import Foundation

struct SessionFeedback: Identifiable, Equatable, Codable {
    let id: String
    let sessionId: UUID
    let fillerWordCount: Int
    let mispronouncedWords: [String]
    let fluencyScore: Double   
    let onTopicScore: Double
    let pauses: Int 
    let summary: String
    let createdAt: Date
    
    static func ==(lhs: SessionFeedback, rhs: SessionFeedback) -> Bool {
        return lhs.id == rhs.id
    }
}
