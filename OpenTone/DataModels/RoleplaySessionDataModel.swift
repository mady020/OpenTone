import Foundation

@MainActor
class RoleplaySessionDataModel {

    static let shared = RoleplaySessionDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private var savedSessionURL: URL {
        documentsDirectory
            .appendingPathComponent("saved_roleplay_session")
            .appendingPathExtension("json")
    }

    private var savedScenarioURL: URL {
        documentsDirectory
            .appendingPathComponent("saved_roleplay_scenario")
            .appendingPathExtension("json")
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    private(set) var activeSession: RoleplaySession?
    var activeScenario: RoleplayScenario?

    func startSession(scenarioId: UUID) -> RoleplaySession? {

        guard let user = UserDataModel.shared.getCurrentUser() else {
            return nil
        }

        let newSession = RoleplaySession(
            userId: user.id,
            scenarioId: scenarioId
        )

        activeSession = newSession
        activeScenario = RoleplayScenarioDataModel.shared.getScenario(by: scenarioId)

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
        activeScenario = scenario

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
                isCompleted: true,
                scenarioId: scenario.id
            )

            activeSession = nil
            activeScenario = nil
            // Clear any saved session since this one completed
            deleteSavedSession()
        }
    }

    //  Save & Exit

    /// Save the current session + scenario to disk for later resumption, then clear active.
    func saveSessionForLater() {
        guard let session = activeSession,
              let scenario = activeScenario else { return }

        var pausedSession = session
        pausedSession.status = .paused

        if let data = try? encoder.encode(pausedSession) {
            try? data.write(to: savedSessionURL, options: .atomic)
        }
        if let data = try? encoder.encode(scenario) {
            try? data.write(to: savedScenarioURL, options: .atomic)
        }

        activeSession = nil
        activeScenario = nil
    }

    /// Check if there is a previously saved (paused) session.
    func hasSavedSession() -> Bool {
        FileManager.default.fileExists(atPath: savedSessionURL.path)
    }

    /// Peek at the saved session without making it active.
    func getSavedSession() -> RoleplaySession? {
        guard let data = try? Data(contentsOf: savedSessionURL),
              let session = try? decoder.decode(RoleplaySession.self, from: data) else {
            return nil
        }
        return session
    }

    /// Peek at the saved scenario.
    func getSavedScenario() -> RoleplayScenario? {
        guard let data = try? Data(contentsOf: savedScenarioURL),
              let scenario = try? decoder.decode(RoleplayScenario.self, from: data) else {
            return nil
        }
        return scenario
    }

    /// Resume a previously saved session, making it active again.
    @discardableResult
    func resumeSavedSession() -> (RoleplaySession, RoleplayScenario)? {
        guard let sessionData = try? Data(contentsOf: savedSessionURL),
              let session = try? decoder.decode(RoleplaySession.self, from: sessionData),
              let scenarioData = try? Data(contentsOf: savedScenarioURL),
              let scenario = try? decoder.decode(RoleplayScenario.self, from: scenarioData) else {
            return nil
        }

        var resumed = session
        resumed.status = .inProgress

        activeSession = resumed
        activeScenario = scenario
        deleteSavedSession()
        return (resumed, scenario)
    }

    /// Delete saved session files.
    func deleteSavedSession() {
        try? FileManager.default.removeItem(at: savedSessionURL)
        try? FileManager.default.removeItem(at: savedScenarioURL)
    }

    func cancelSession() {
        activeSession = nil
        activeScenario = nil
    }
}
