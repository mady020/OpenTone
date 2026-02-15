import Foundation

@MainActor
class RoleplaySessionDataModel {

    static let shared = RoleplaySessionDataModel()

    private init() {}

    private(set) var activeSession: RoleplaySession?



    func startSession(scenarioId: UUID) -> RoleplaySession? {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            return nil
        }

        let newSession = RoleplaySession(
            userId: user.id,
            scenarioId: scenarioId
        )

        activeSession = newSession


        UserDataModel.shared.addRoleplayID(newSession.id)

        return newSession
    }

    func getActiveSession() -> RoleplaySession? {
        return activeSession
    }

    func updateSession(_ updated: RoleplaySession, scenario: RoleplayScenario) {
        guard let current = activeSession,
              current.id == updated.id else {
            return
        }

        activeSession = updated


        if current.status != .completed && updated.status == .completed {

            let duration: Int
            if let end = updated.endedAt {
                duration = Int(end.timeIntervalSince(updated.startedAt))
            } else {
                duration = 0
            }

    
            HistoryDataModel.shared.logActivity(
                type: .roleplay,
                title: scenario.title,
                topic: scenario.description,
                duration: duration,
                imageURL: scenario.imageURL,
                xpEarned: 12,
                isCompleted: true
            )

            activeSession = nil
        }
    }


    func cancelSession() {
        activeSession = nil
    }
}
