import Foundation

struct JamSession: Identifiable, Codable, Equatable {

    static let availableTopics: [String] = [
        "The Future of Technology",
        "Climate Change and Its Impact",
        "The Role of Art in Society",
        "Exploring Space: The Next Frontier",
        "The Evolution of Education",
    ]

    let id: UUID
    let userId: UUID

    let topic: String
    var phase: JamPhase

    var startedPrepAt: Date?
    var startedSpeakingAt: Date?
    var endedAt: Date?

    var transcript: String?
    var feedback: SessionFeedback?

    var suggestions : [String]

    init(
        userId: UUID,
        phase: JamPhase,
        startedPrepAt: Date? = nil,
        startedSpeakingAt: Date? = nil,
        endedAt: Date? = nil,
        transcript: String? = nil,
        feedback: SessionFeedback? = nil,
        suggestions: [String] = []
    ) {
        self.id = UUID()
        self.userId = userId
        self.topic = Self.availableTopics.randomElement() ?? "General Topic"
        self.phase = phase
        self.startedPrepAt = startedPrepAt
        self.startedSpeakingAt = startedSpeakingAt
        self.endedAt = endedAt
        self.transcript = transcript
        self.feedback = feedback
        self.suggestions = suggestions
    }

    static func == (lhs: JamSession, rhs: JamSession) -> Bool {
        lhs.id == rhs.id
    }
}
