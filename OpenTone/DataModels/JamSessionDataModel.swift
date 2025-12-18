import Foundation

@MainActor
class JamSessionDataModel {

    static let shared = JamSessionDataModel()

    private var activeSession: JamSession?

    private init() {}

    func startJamSession(
        phase: JamPhase = .preparing,
        initialSeconds: Int = 120
    ) -> JamSession? {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            return nil
        }

        let topic = generateRandomTopic()
        let suggestions = generateSuggestions(for: topic)

        let session = JamSession(
            userId: user.id,
            topic: topic,
            suggestions: suggestions,
            phase: phase,
            secondsLeft: initialSeconds
        )

        activeSession = session
        return session
    }

    func getActiveSession() -> JamSession? {
        activeSession
    }

    func hasActiveSession() -> Bool {
        activeSession != nil
    }

    func continueActiveSession() -> JamSession? {
        guard var session = activeSession else { return nil }

        session.secondsLeft = min(session.secondsLeft + 3, 120)
        activeSession = session
        return session
    }

    func regenerateTopicForActiveSession() -> JamSession? {
        guard var session = activeSession else { return nil }

        let newTopic = generateRandomTopic()
        session.topic = newTopic
        session.suggestions = generateSuggestions(for: newTopic)
        session.secondsLeft = 120
        session.startedPrepAt = Date()

        activeSession = session
        return session
    }

    func updateActiveSession(_ updated: JamSession) {
        guard let current = activeSession,
              current.id == updated.id else { return }

        activeSession = updated

        if current.phase != .completed,
           updated.phase == .completed {

            let duration: Int
            if let start = updated.startedSpeakingAt,
               let end = updated.endedAt {
                duration = Int(end.timeIntervalSince(start))
            } else {
                duration = 0
            }

            UserDataModel.shared.addJamSessionID(updated.id)

            HistoryDataModel.shared.logActivity(
                type: .jam,
                title: "Speaking Jam",
                topic: updated.topic,
                duration: duration,
                imageURL: "jam_icon",
                xpEarned: 10,
                isCompleted: true
            )

            activeSession = nil
        }
    }

    func cancelJamSession() {
        activeSession = nil
    }

    func startNewSession() {
        _ = startJamSession()
    }

    func continueSession() {
        _ = continueActiveSession()
    }

    func generateSpeakingHints() -> [String] {

        let allHints = [
            "Start with a brief introduction",
            "Share a personal experience",
            "Ask a thought-provoking question",
            "Use data to support your points",
            "Give a real-world example",
            "Explain one key idea clearly",
            "Summarize with a strong conclusion",
            "Keep your points simple",
            "Use clear transitions",
            "Speak with confidence"
        ]

        return Array(allHints.shuffled().prefix(3))
    }

    private func generateRandomTopic() -> String {
        JamSession.availableTopics.randomElement() ?? "General Topic"
    }

    private func generateSuggestions(for topic: String) -> [String] {

        let lower = topic.lowercased()

        switch lower {

        case let t where t.contains("technology"):
            return [
                "AI impact on society",
                "future gadgets",
                "automation and jobs",
                "virtual reality innovations",
                "ethical technology",
                "cybersecurity challenges"
            ]

        case let t where t.contains("climate"):
            return [
                "global warming causes",
                "renewable energy solutions",
                "carbon footprint reduction",
                "environmental policies",
                "climate change awareness",
                "sustainable living"
            ]

        case let t where t.contains("space"):
            return [
                "benefits of space exploration",
                "future space missions",
                "life on other planets",
                "space technology advances",
                "challenges of space travel",
                "private space companies"
            ]

        case let t where t.contains("education"):
            return [
                "online learning impact",
                "future classrooms",
                "AI in education",
                "skill-based learning",
                "education accessibility",
                "role of teachers"
            ]

        default:
            return [
                "background and context",
                "key challenges",
                "real-world examples",
                "future opportunities",
                "common misconceptions",
                "important takeaways"
            ]
        }
    }
}
