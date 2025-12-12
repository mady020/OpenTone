import Foundation

struct RoleplayMessage: Identifiable, Codable {
    let id: UUID
    let sender: RoleplaySender
    let text: String
    let timestamp: Date
    let suggestedMessages: [String]?

    init(sender: RoleplaySender, text: String, timestamp: Date = Date(), suggestedMessages: [String]? ) {
        self.id = UUID()
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.suggestedMessages = suggestedMessages
    }
}

enum RoleplaySender: String, Codable {
    case app
    case user
}
