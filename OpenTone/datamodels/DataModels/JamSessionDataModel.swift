import Foundation

@MainActor
class JamSessionDataModel {

    static let shared = JamSessionDataModel()

    private var activeSession: JamSession?

    private init() {}

    func startJamSession(phase: JamPhase = .preparing) -> JamSession? {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            return nil
        }

        let newSession = JamSession(
            userId: user.id,
            phase: phase
        )

        activeSession = newSession
        return newSession
    }

    func getActiveSession() -> JamSession? {
        return activeSession
    }

    func updateActiveSession(_ updated: JamSession) {
        guard let current = activeSession,
            current.id == updated.id
        else {
            return
        }

        activeSession = updated

        if current.phase != .completed && updated.phase == .completed {

            let duration: Int
            if let start = updated.startedSpeakingAt,
                let end = updated.endedAt
            {
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

    func generateSuggestions(_ topic: String) -> [String] {

        let lower = topic.lowercased()

        switch lower {

        case let t where t.contains("technology"):
            return [
                "AI impact on society",
                "future gadgets",
                "automation and jobs",
                "virtual reality innovations",
                "ethical technology",
            ]

        case let t where t.contains("climate"):
            return [
                "global warming causes",
                "climate solutions",
                "renewable energy",
                "carbon footprint",
                "environmental policies",
            ]
        default:
            return [
                "\(topic) explanation",
                "\(topic) key points",
                "\(topic) advantages and disadvantages",
                "\(topic) common questions",
                "\(topic) important facts",
            ]
        }
    }

    func cancelJamSession() {
        activeSession = nil
    }
}
