import Foundation

@MainActor
class JamSessionDataModel {

    static let shared = JamSessionDataModel()

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

    @discardableResult
    func startJamSession(
        phase: JamPhase = .preparing,
        initialSeconds: Int = 30
    ) -> JamSession? {
        return startNewSession()
    }

    func getActiveSession() -> JamSession? {
        activeSession
    }

    func hasActiveSession() -> Bool {
        activeSession != nil
    }

    func updateActiveSession(_ updated: JamSession) {
        guard let current = activeSession, current.id == updated.id else { return }

        activeSession = updated
        persistActiveSession()

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
        persistActiveSession()
    }

    @discardableResult
    func continueSession() -> JamSession? {
        return activeSession
    }

    @discardableResult
    func continueActiveSession() -> JamSession? {
        return activeSession
    }

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

    func regenerateTopicWithAI(completion: @escaping (JamSession?) -> Void) {
        guard var session = activeSession else {
            completion(nil)
            return
        }

        Task {
            do {
                let result = try await GeminiService.shared.generateJamTopic()
                session.topic = result.topic
                session.suggestions = result.hints
                session.secondsLeft = 30
                session.startedPrepAt = Date()
                self.activeSession = session
                self.persistActiveSession()
                completion(session)
            } catch {
                print("⚠️ Gemini JAM topic generation failed: \(error.localizedDescription). Using fallback.")
                let fallback = self.regenerateTopicForActiveSession()
                completion(fallback)
            }
        }
    }

    func startNewSessionWithAI(completion: @escaping (JamSession?) -> Void) {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            completion(nil)
            return
        }

        Task {
            do {
                let result = try await GeminiService.shared.generateJamTopic()

                let session = JamSession(
                    userId: user.id,
                    topic: result.topic,
                    suggestions: result.hints,
                    phase: .preparing,
                    secondsLeft: 30
                )

                self.activeSession = session
                self.persistActiveSession()
                completion(session)
            } catch {
                print("⚠️ Gemini topic generation failed: \(error.localizedDescription). Using fallback.")
                let session = self.startNewSession()
                completion(session)
            }
        }
    }

    func saveSessionForLater() {
        guard let session = activeSession else { return }
        if let data = try? encoder.encode(session) {
            try? data.write(to: savedSessionURL, options: .atomic)
        }
        activeSession = nil
        clearActiveSessionFile()
    }

    func hasSavedSession() -> Bool {
        FileManager.default.fileExists(atPath: savedSessionURL.path)
    }

    func getSavedSession() -> JamSession? {
        guard let data = try? Data(contentsOf: savedSessionURL),
              let session = try? decoder.decode(JamSession.self, from: data) else {
            return nil
        }
        return session
    }

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

    func deleteSavedSession() {
        try? FileManager.default.removeItem(at: savedSessionURL)
    }

    func cancelJamSession() {
        activeSession = nil
        clearActiveSessionFile()
    }


    func getCompletedSessions() -> [JamSession] {
        completedSessions
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
