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

    func continueActiveSession() -> JamSession? {
        guard var session = activeSession else { return nil }

        session.secondsLeft = min(session.secondsLeft + 10, 120)
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
                "ethical technology"
            ]

        case let t where t.contains("climate"):
            return [
                "global warming causes",
                "climate solutions",
                "renewable energy",
                "carbon footprint",
                "environmental policies"
            ]

        default:
            return [
                "\(topic) explanation",
                "\(topic) key points",
                "\(topic) advantages and disadvantages",
                "\(topic) common questions",
                "\(topic) important facts"
            ]
        }
    }
}

extension JamSessionDataModel {

    func startNewSession() {
        _ = startJamSession()
    }

    func continueSession() {
        _ = continueActiveSession()
    }

    func hasActiveSession() -> Bool {
        activeSession != nil
    }
}
