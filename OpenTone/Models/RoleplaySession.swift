import Foundation

struct RoleplaySession: Identifiable, Codable, Equatable {

    private(set) var id: UUID
    
    /// Override the auto-generated UUID (used when loading from Supabase).
    mutating func setID(_ newID: UUID) { id = newID }

    let userId: UUID
    let scenarioId: UUID

    var currentLineIndex: Int
    var messages: [RoleplayMessage]

    var status: RoleplayStatus
    let startedAt: Date
    var endedAt: Date?
    var feedback: SessionFeedback?
    var xpEarned: Int

    init(
        userId: UUID,
        scenarioId: UUID,
        status: RoleplayStatus = .notStarted,
        startedAt: Date = Date(),
        xpEarned: Int = 100
    ) {
        self.id = UUID()
        self.userId = userId
        self.scenarioId = scenarioId
        self.status = status
        self.startedAt = startedAt
        self.endedAt = nil
        self.feedback = nil
        self.currentLineIndex = 0
        self.messages = []
        self.xpEarned = xpEarned
    }

    static func == (lhs: RoleplaySession, rhs: RoleplaySession) -> Bool {
        lhs.id == rhs.id
    }
}
