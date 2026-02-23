import Foundation

struct JamSession: Identifiable, Equatable, Codable {

    static let availableTopics: [String] = [
        "The Future of Technology",
        "Climate Change and Its Impact",
        "The Role of Art in Society",
        "Exploring Space: The Next Frontier",
        "The Evolution of Education"
    ]

    private(set) var id: UUID
    let userId: UUID
    
    /// Override the auto-generated UUID (used when loading from Supabase).
    mutating func setID(_ newID: UUID) { id = newID }

    var topic: String
    var suggestions: [String]

    var phase: JamPhase

    var secondsLeft: Int

    var startedPrepAt: Date?
    var startedSpeakingAt: Date?
    var endedAt: Date?

    init(
        userId: UUID,
        topic: String,
        suggestions: [String],
        phase: JamPhase = .preparing,
        secondsLeft: Int = 10
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

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, userId, topic, suggestions, phase, secondsLeft
        case startedPrepAt, startedSpeakingAt, endedAt
    }
}
