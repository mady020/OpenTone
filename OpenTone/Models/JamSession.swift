import Foundation

struct JamSession: Identifiable, Equatable {

    static let availableTopics: [String] = [
        "The Future of Technology",
        "Climate Change and Its Impact",
        "The Role of Art in Society",
        "Exploring Space: The Next Frontier",
        "The Evolution of Education"
    ]

    let id: UUID
    let userId: UUID

    // Topic data
    var topic: String
    var suggestions: [String]

    // Session phase
    var phase: JamPhase

    // Timer
    var secondsLeft: Int

    // Timestamps
    var startedPrepAt: Date?
    var startedSpeakingAt: Date?
    var endedAt: Date?

    init(
        userId: UUID,
        topic: String,
        suggestions: [String],
        phase: JamPhase = .preparing,
        secondsLeft: Int = 120
    ) {
        self.id = UUID()
        self.userId = userId
        self.topic = topic
        self.suggestions = suggestions
        self.phase = phase
        self.secondsLeft = secondsLeft
        self.startedPrepAt = Date()
        self.startedSpeakingAt = nil
        self.endedAt = nil
    }

    static func == (lhs: JamSession, rhs: JamSession) -> Bool {
        lhs.id == rhs.id
    }
}
