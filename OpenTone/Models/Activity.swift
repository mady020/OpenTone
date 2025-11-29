import Foundation

struct Activity: Equatable, Codable {
    let id: UUID
    let type: ActivityType
    let title: String
    let date: Date
    let topic : String
    let duration: Int
    let imageURL: String
    let xpEarned: Int
    let isCompleted: Bool
    let roleplaySession: RoleplaySession?
    let feedback: SessionFeedback? 
    init( type: ActivityType, date: Date, topic: String, duration: Int, xpEarned: Int, isCompleted: Bool = false, title: String, imageURL: String, roleplaySession: RoleplaySession? = nil, feedback: SessionFeedback? = nil) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.imageURL = imageURL
        self.topic = topic
        self.duration = duration
        self.xpEarned = xpEarned
        self.isCompleted = isCompleted
        self.title = type.rawValue
        self.roleplaySession = roleplaySession
        self.feedback = feedback
    }
    
    static func ==(lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
}

