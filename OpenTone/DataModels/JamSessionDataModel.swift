import Foundation
internal import PostgREST
import Supabase

@MainActor
class JamSessionDataModel {

    static let shared = JamSessionDataModel()

    private var activeSession: JamSession?
    private var completedSessions: [JamSession] = []

    private init() {
        Task {
            await loadCompletedSessions()
        }
    }

    /// Clears in-memory data and reloads for the current user.
    func reloadForCurrentUser() {
        activeSession = nil
        completedSessions = []
        _savedSessionCache = nil
        _hasSavedSessionCached = false
        Task {
            await loadCompletedSessions()
        }
    }

    // MARK: - Start Session

    @discardableResult
    func startNewSession() -> JamSession? {
        guard let user = UserDataModel.shared.getCurrentUser() else { return nil }

        let topic = generateRandomTopic()
        let suggestions = generateSuggestions(for: topic)

        let session = JamSession(
            userId: user.id,
            topic: topic,
            suggestions: suggestions,
            phase: .preparing,
            secondsLeft: 30
        )

        activeSession = session
        let captured = session
        Task { await upsertSessionInSupabase(captured) }
        return session
    }

    @discardableResult
    func startJamSession(
        phase: JamPhase = .preparing,
        initialSeconds: Int = 30
    ) -> JamSession? {
        return startNewSession()
    }

    // MARK: - Active Session

    func getActiveSession() -> JamSession? {
        activeSession
    }

    func hasActiveSession() -> Bool {
        activeSession != nil
    }

    // MARK: - Session Updates

    func updateActiveSession(_ updated: JamSession) {
        guard let current = activeSession, current.id == updated.id else { return }

        activeSession = updated
        let captured = updated
        Task { await upsertSessionInSupabase(captured) }

        if current.phase != .completed && updated.phase == .completed {
            archiveCompletedSession(updated)
        }
    }

    func beginSpeakingPhase() {
        guard var session = activeSession else { return }
        session.phase = .speaking
        session.startedSpeakingAt = Date()
        session.secondsLeft = 30
        activeSession = session
        let captured = session
        Task { await upsertSessionInSupabase(captured) }
    }

    @discardableResult
    func continueSession() -> JamSession? {
        return activeSession
    }

    @discardableResult
    func continueActiveSession() -> JamSession? {
        return activeSession
    }

    // MARK: - Regenerate Topic

    @discardableResult
    func regenerateTopicForActiveSession() -> JamSession? {
        guard var session = activeSession else { return nil }

        let newTopic = generateRandomTopic()
        session.topic = newTopic
        session.suggestions = generateSuggestions(for: newTopic)
        session.secondsLeft = 30
        session.startedPrepAt = Date()

        activeSession = session
        let captured = session
        Task { await upsertSessionInSupabase(captured) }
        return session
    }

    // regenerateTopicWithAI and startNewSessionWithAI removed.
    // The local fallbacks (generateRandomTopic / generateSuggestions) are now the default.

    // MARK: - Save & Exit

    func saveSessionForLater() {
        guard let session = activeSession else { return }
        let captured = session

        // Update in-memory cache so dashboard sees it immediately
        _savedSessionCache = captured
        _hasSavedSessionCached = true

        activeSession = nil

        Task {
            await upsertSessionInSupabase(captured, isSaved: true)
        }
    }

    func hasSavedSession() -> Bool {
        // Check in-memory cache of completed sessions for a saved one
        // For a synchronous check, we rely on a cached flag.
        return _hasSavedSessionCached
    }

    private var _hasSavedSessionCached: Bool = false

    func getSavedSession() -> JamSession? {
        return _savedSessionCache
    }

    private var _savedSessionCache: JamSession?

    /// Load saved session from Supabase (call at app launch or when checking).
    func refreshSavedSession() {
        Task {
            await loadSavedSession()
        }
    }

    @discardableResult
    func resumeSavedSession() -> JamSession? {
        guard let saved = _savedSessionCache else { return nil }
        activeSession = saved
        _savedSessionCache = nil
        _hasSavedSessionCached = false

        let captured = saved
        Task {
            await upsertSessionInSupabase(captured, isSaved: false)
        }
        return saved
    }

    func deleteSavedSession() {
        _savedSessionCache = nil
        _hasSavedSessionCached = false
    }

    func cancelJamSession() {
        if let session = activeSession {
            Task {
                await deleteSessionFromSupabase(session.id)
            }
        }
        activeSession = nil
    }

    // MARK: - Completed Sessions

    func getCompletedSessions() -> [JamSession] {
        completedSessions
    }

    // MARK: - Hints

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

    // MARK: - Supabase Operations

    /// Upsert a captured session snapshot. Never reads from `activeSession`.
    private func upsertSessionInSupabase(_ session: JamSession, isSaved: Bool = false) async {
        do {
            let row = JamSessionRow(from: session, isSaved: isSaved)
            try await supabase
                .from(SupabaseTable.jamSessions)
                .upsert(row)
                .execute()
        } catch {
            print("❌ Failed to upsert jam session: \(error.localizedDescription)")
        }
    }

    private func loadSavedSession() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let rows: [JamSessionRow] = try await supabase
                .from(SupabaseTable.jamSessions)
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("is_saved", value: true)
                .limit(1)
                .execute()
                .value

            if let row = rows.first {
                _savedSessionCache = row.toJamSession()
                _hasSavedSessionCached = true
            } else {
                _savedSessionCache = nil
                _hasSavedSessionCached = false
            }
        } catch {
            print("❌ Failed to load saved session: \(error.localizedDescription)")
        }
    }

    private func loadCompletedSessions() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let rows: [JamSessionRow] = try await supabase
                .from(SupabaseTable.jamSessions)
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("phase", value: "completed")
                .order("ended_at", ascending: false)
                .execute()
                .value
            completedSessions = rows.map { $0.toJamSession() }
        } catch {
            print("❌ Failed to load completed jam sessions: \(error.localizedDescription)")
            completedSessions = []
        }

        // Also load any saved session
        await loadSavedSession()
    }

    private func deleteSessionFromSupabase(_ id: UUID) async {
        do {
            try await supabase
                .from(SupabaseTable.jamSessions)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("❌ Failed to delete jam session: \(error.localizedDescription)")
        }
    }

    private func archiveCompletedSession(_ session: JamSession) {
        completedSessions.append(session)

        let durationSeconds: Int
        if let start = session.startedSpeakingAt, let end = session.endedAt {
            durationSeconds = Int(end.timeIntervalSince(start))
        } else {
            durationSeconds = 0
        }
        
        // Convert to minutes for history and streak tracking
        let durationMinutes = max(1, durationSeconds / 60)

        UserDataModel.shared.addJamSessionID(session.id)

        HistoryDataModel.shared.logActivity(
            type: .jam,
            title: "Speaking Jam",
            topic: session.topic,
            duration: durationMinutes,
            imageURL: "jam_icon",
            xpEarned: 10,
            isCompleted: true
        )

        SessionProgressManager.shared.markCompleted(.twoMinJam, topic: session.topic, actualDurationMinutes: durationMinutes)

        activeSession = nil
    }

    // MARK: - Topic Generation

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
