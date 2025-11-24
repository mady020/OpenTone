import Foundation

struct RoleplayMessage: Identifiable, Codable {
    let id: UUID
    let sender: RoleplaySender
    let text: String
    let timestamp: Date

    init(sender: RoleplaySender, text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
}

enum RoleplaySender: String, Codable {
    case app
    case user
}
