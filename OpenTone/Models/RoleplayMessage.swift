import Foundation

enum RoleplaySpeaker: String, Codable {
    case npc
    case user
}

struct RoleplayMessage: Identifiable, Codable, Equatable {

    let id: UUID
    let speaker: RoleplaySpeaker

    /// NPC line OR user selected reply
    let text: String

    /// Only filled for NPC messages
    /// These are the selectable user replies
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
