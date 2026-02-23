import Foundation
internal import PostgREST
import Supabase

@MainActor
class RoleplaySessionDataModel {

    static let shared = RoleplaySessionDataModel()

    private init() {}

    private(set) var activeSession: RoleplaySession?
    var activeScenario: RoleplayScenario?

    /// Clears in-memory data and reloads for the current user.
    func reloadForCurrentUser() {
        activeSession = nil
        activeScenario = nil
        _savedSessionCache = nil
        _savedScenarioCache = nil
        _hasSavedSessionCached = false
        refreshSavedSession()
    }

    // MARK: - Start

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

        let captured = newSession
        Task {
            await upsertSessionInSupabase(captured)
        }

        return newSession
    }

    // MARK: - Read

    func getActiveSession() -> RoleplaySession? {
        return activeSession
    }

    // MARK: - Update

    func updateSession(_ updated: RoleplaySession, scenario: RoleplayScenario) {
        guard let current = activeSession,
              current.id == updated.id else {
            return
        }

        activeSession = updated
        activeScenario = scenario

        // Capture BEFORE any potential nil-out below
        let captured = updated
        Task {
            await upsertSessionInSupabase(captured)
        }

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
            deleteSavedSession()
        }
    }

    // MARK: - Save & Exit

    func saveSessionForLater() {
        guard var session = activeSession else { return }

        // Capture + mark paused BEFORE nilling
        session.status = .paused
        let captured = session

        // Update in-memory cache so dashboard sees it immediately
        _savedSessionCache = captured
        _savedScenarioCache = activeScenario
        _hasSavedSessionCached = true

        activeSession = nil
        activeScenario = nil

        Task {
            await upsertSessionInSupabase(captured, isSaved: true)
        }
    }

    func hasSavedSession() -> Bool {
        return _hasSavedSessionCached
    }

    private var _hasSavedSessionCached: Bool = false
    private var _savedSessionCache: RoleplaySession?
    private var _savedScenarioCache: RoleplayScenario?

    func getSavedSession() -> RoleplaySession? {
        return _savedSessionCache
    }

    func getSavedScenario() -> RoleplayScenario? {
        return _savedScenarioCache
    }

    /// Load saved session info from Supabase (call at app launch or when checking).
    func refreshSavedSession() {
        Task {
            await loadSavedSession()
        }
    }

    @discardableResult
    func resumeSavedSession() -> (RoleplaySession, RoleplayScenario)? {
        guard let session = _savedSessionCache,
              let scenario = _savedScenarioCache else { return nil }

        var resumed = session
        resumed.status = .inProgress

        activeSession = resumed
        activeScenario = scenario

        _savedSessionCache = nil
        _savedScenarioCache = nil
        _hasSavedSessionCached = false

        let captured = resumed
        Task {
            await upsertSessionInSupabase(captured, isSaved: false)
        }

        return (resumed, scenario)
    }

    func deleteSavedSession() {
        _savedSessionCache = nil
        _savedScenarioCache = nil
        _hasSavedSessionCached = false
    }

    func cancelSession() {
        activeSession = nil
        activeScenario = nil
    }

    // MARK: - Supabase Operations

    /// Upsert a captured session snapshot. Never reads from `activeSession`.
    private func upsertSessionInSupabase(_ session: RoleplaySession, isSaved: Bool = false) async {
        do {
            let row = RoleplaySessionRow(from: session, isSaved: isSaved)
            try await supabase
                .from(SupabaseTable.roleplaySessions)
                .upsert(row)
                .execute()
        } catch {
            print("❌ Failed to upsert roleplay session: \(error.localizedDescription)")
        }
    }

    private func loadSavedSession() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let rows: [RoleplaySessionRow] = try await supabase
                .from(SupabaseTable.roleplaySessions)
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("is_saved", value: true)
                .limit(1)
                .execute()
                .value

            if let row = rows.first {
                let session = row.toRoleplaySession()
                _savedSessionCache = session
                _savedScenarioCache = RoleplayScenarioDataModel.shared.getScenario(by: session.scenarioId)
                _hasSavedSessionCached = true
            } else {
                _savedSessionCache = nil
                _savedScenarioCache = nil
                _hasSavedSessionCached = false
            }
        } catch {
            print("❌ Failed to load saved roleplay session: \(error.localizedDescription)")
        }
    }
}
