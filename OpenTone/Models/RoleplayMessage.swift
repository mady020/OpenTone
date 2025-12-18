import Foundation

enum RoleplaySpeaker: String, Codable {
    case npc
    case user
}

struct RoleplayMessage: Identifiable, Codable, Equatable {

    let id: UUID
    let speaker: RoleplaySpeaker
    let text: String
    let replyOptions: [String]?

    init(
        speaker: RoleplaySpeaker,
        text: String,
        replyOptions: [String]? = nil
    ) {
        self.id = UUID()
        self.speaker = speaker
        self.text = text
        self.replyOptions = replyOptions
    }
}
