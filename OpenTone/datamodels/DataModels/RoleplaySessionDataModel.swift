import Foundation

@MainActor
class RoleplaySessionDataModel {

    static let shared = RoleplaySessionDataModel()

    private init() {}

    private(set) var activeSession: RoleplaySession?


    /// Starts a new roleplay session and assigns it as the active one.
    func startSession(scenarioId: UUID) -> RoleplaySession? {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            return nil
        }

        let newSession = RoleplaySession(
            userId: user.id,
            scenarioId: scenarioId
        )

        activeSession = newSession

        // Update user's roleplay list
        UserDataModel.shared.addRoleplayID(newSession.id)

        return newSession
    }

    /// Returns the currently active session (if any)
    func getActiveSession() -> RoleplaySession? {
        return activeSession
    }

    /// Updates the active roleplay session (messages, status, etc.)
    /// If session moves to `.completed`, history is logged automatically.
    func updateSession(_ updated: RoleplaySession, scenario: RoleplayScenario) {
        guard let current = activeSession,
              current.id == updated.id else {
            return
        }

        activeSession = updated

        // Log only when the session transitions to completed
        if current.status != .completed && updated.status == .completed {

            let duration: Int
            if let end = updated.endedAt {
                duration = Int(end.timeIntervalSince(updated.startedAt))
            } else {
                duration = 0
            }

            // Log roleplay activity
            HistoryDataModel.shared.logActivity(
                type: .roleplay,
                title: scenario.title,
                topic: scenario.description,
                duration: duration,
                imageURL: scenario.imageURL,
                xpEarned: 12,
                isCompleted: true
            )

            // Clear the active session
            activeSession = nil
        }
    }

    /// Cancels the current session without logging.
    func cancelSession() {
        activeSession = nil
    }
}