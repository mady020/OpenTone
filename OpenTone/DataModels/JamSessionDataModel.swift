import Foundation

@MainActor
class JamSessionDataModel {

    static let shared = JamSessionDataModel()

    // MARK: - Persistence

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private var activeSessionURL: URL {
        documentsDirectory
            .appendingPathComponent("active_jam_session")
            .appendingPathExtension("json")
    }

    private var completedSessionsURL: URL {
        documentsDirectory
            .appendingPathComponent("completed_jam_sessions")
            .appendingPathExtension("json")
    }

    private var savedSessionURL: URL {
        documentsDirectory
            .appendingPathComponent("saved_jam_session")
            .appendingPathExtension("json")
    }

    // MARK: - State

    private var activeSession: JamSession?
    private var completedSessions: [JamSession] = []

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

    private init() {
        loadActiveSession()
        loadCompletedSessions()
    }

    // MARK: - Session Lifecycle

    /// Creates a brand-new session with a random topic, stores it as active, and persists.
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
        persistActiveSession()
        return session
    }

    /// Alias kept for backward compatibility.
    @discardableResult
    func startJamSession(
        phase: JamPhase = .preparing,
        initialSeconds: Int = 30
    ) -> JamSession? {
        return startNewSession()
    }

    // MARK: - Active Session Queries

    func getActiveSession() -> JamSession? {
        activeSession
    }

    func hasActiveSession() -> Bool {
        activeSession != nil
    }

    // MARK: - Session Updates

    /// Update the active session in-memory and persist to disk.
    func updateActiveSession(_ updated: JamSession) {
        guard let current = activeSession, current.id == updated.id else { return }

        activeSession = updated
        persistActiveSession()

        // If the session just completed, archive it.
        if current.phase != .completed && updated.phase == .completed {
            archiveCompletedSession(updated)
        }
    }

    /// Transition the active session into the speaking phase.
    func beginSpeakingPhase() {
        guard var session = activeSession else { return }
        session.phase = .speaking
        session.startedSpeakingAt = Date()
        session.secondsLeft = 30   // speaking timer
        activeSession = session
        persistActiveSession()
    }

    /// Continue the current session (no-op if nil). Returns the session.
    @discardableResult
    func continueSession() -> JamSession? {
        return activeSession
    }

    /// Continue the active session, optionally adding bonus seconds.
    @discardableResult
    func continueActiveSession() -> JamSession? {
        return activeSession
    }

    /// Regenerate a new random topic for the current active session.
    @discardableResult
    func regenerateTopicForActiveSession() -> JamSession? {
        guard var session = activeSession else { return nil }

        let newTopic = generateRandomTopic()
        session.topic = newTopic
        session.suggestions = generateSuggestions(for: newTopic)
        session.secondsLeft = 30
        session.startedPrepAt = Date()

        activeSession = session
        persistActiveSession()
        return session
    }

    // MARK: - Save & Exit

    /// Save the current session to disk for later resumption, then clear active.
    func saveSessionForLater() {
        guard let session = activeSession else { return }
        if let data = try? encoder.encode(session) {
            try? data.write(to: savedSessionURL, options: .atomic)
        }
        activeSession = nil
        clearActiveSessionFile()
    }

    /// Check if there is a previously saved (paused) session.
    func hasSavedSession() -> Bool {
        FileManager.default.fileExists(atPath: savedSessionURL.path)
    }

    /// Peek at the saved session without making it active.
    func getSavedSession() -> JamSession? {
        guard let data = try? Data(contentsOf: savedSessionURL),
              let session = try? decoder.decode(JamSession.self, from: data) else {
            return nil
        }
        return session
    }

    /// Resume a previously saved session, making it active again.
    @discardableResult
    func resumeSavedSession() -> JamSession? {
        guard let data = try? Data(contentsOf: savedSessionURL),
              let session = try? decoder.decode(JamSession.self, from: data) else {
            return nil
        }
        activeSession = session
        persistActiveSession()
        deleteSavedSession()
        return session
    }

    /// Delete the saved session file without loading it.
    func deleteSavedSession() {
        try? FileManager.default.removeItem(at: savedSessionURL)
    }

    /// Discard the active session entirely (no save).
    func cancelJamSession() {
        activeSession = nil
        clearActiveSessionFile()
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

    // MARK: - Private Persistence Helpers

    private func persistActiveSession() {
        guard let session = activeSession,
              let data = try? encoder.encode(session) else { return }
        try? data.write(to: activeSessionURL, options: .atomic)
    }

    private func clearActiveSessionFile() {
        try? FileManager.default.removeItem(at: activeSessionURL)
    }

    private func loadActiveSession() {
        guard let data = try? Data(contentsOf: activeSessionURL),
              let session = try? decoder.decode(JamSession.self, from: data) else {
            activeSession = nil
            return
        }
        // Don't resume completed sessions
        if session.phase == .completed {
            activeSession = nil
            clearActiveSessionFile()
        } else {
            activeSession = session
        }
    }

    private func loadCompletedSessions() {
        guard let data = try? Data(contentsOf: completedSessionsURL),
              let sessions = try? decoder.decode([JamSession].self, from: data) else {
            completedSessions = []
            return
        }
        completedSessions = sessions
    }

    private func saveCompletedSessions() {
        guard let data = try? encoder.encode(completedSessions) else { return }
        try? data.write(to: completedSessionsURL, options: .atomic)
    }

    private func archiveCompletedSession(_ session: JamSession) {
        completedSessions.append(session)
        saveCompletedSessions()

        // Log to history
        let duration: Int
        if let start = session.startedSpeakingAt, let end = session.endedAt {
            duration = Int(end.timeIntervalSince(start))
        } else {
            duration = 0
        }

        UserDataModel.shared.addJamSessionID(session.id)

        HistoryDataModel.shared.logActivity(
            type: .jam,
            title: "Speaking Jam",
            topic: session.topic,
            duration: duration,
            imageURL: "jam_icon",
            xpEarned: 10,
            isCompleted: true
        )

        SessionProgressManager.shared.markCompleted(.twoMinJam, topic: session.topic)

        activeSession = nil
        clearActiveSessionFile()
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
