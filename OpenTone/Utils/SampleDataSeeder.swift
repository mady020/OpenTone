import Foundation

/// Seeds rich sample data for the 2 demo users so every screen in the app
/// has realistic content. Called once on quick-sign-in when no history exists.
@MainActor
final class SampleDataSeeder {

    static let shared = SampleDataSeeder()
    private init() {}

    private let seededKeyPrefix = "SampleDataSeeder.hasSeeded"

    /// Per-user seeded flag — uses the current user's ID to scope the key.
    private var seededKey: String {
        if let userId = SessionManager.shared.currentUser?.id {
            return "\(seededKeyPrefix).\(userId.uuidString)"
        }
        return seededKeyPrefix
    }

    var hasSeeded: Bool {
        UserDefaults.standard.bool(forKey: seededKey)
    }

    /// Call this right after quick-sign-in to populate all data stores.
    func seedIfNeeded() {
        guard !hasSeeded else { return }
        seedStreakAndSessions()
        seedHistory()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Force re-seed (for debug / testing)
    func reseed() {
        UserDefaults.standard.set(false, forKey: seededKey)
        seedIfNeeded()
    }

    // MARK: - Streak + Completed Sessions

    private func seedStreakAndSessions() {
        let dm = StreakDataModel.shared
        let cal = Calendar.current

        // Set a healthy streak: 5-day streak, longest 8
        let streak = Streak(
            commitment: 10,
            currentCount: 5,
            longestCount: 8,
            lastActiveDate: cal.startOfDay(for: Date())
        )
        dm.updateStreak(streak)

        // Seed completed sessions over the past 7 days
        let sessionData: [(daysAgo: Int, title: String, subtitle: String,
                           topic: String, duration: Int, xp: Int, icon: String)] = [
            (0, "2 Min Session", "You completed a session", "My Favorite Hobby", 2, 15, "mic.fill"),
            (0, "Roleplay", "You completed a session", "Campus Group Project Kickoff", 12, 25, "theatermasks.fill"),
            (1, "2 Min Session", "You completed a session", "Climate Change", 2, 15, "mic.fill"),
            (2, "Roleplay", "You completed a session", "Behavioral Job Interview", 15, 25, "theatermasks.fill"),
            (2, "2 Min Session", "You completed a session", "Dream Vacation", 2, 15, "mic.fill"),
            (4, "2 Min Session", "You completed a session", "Favorite Movie", 2, 15, "mic.fill"),
            (4, "Roleplay", "You completed a session", "Requesting an Assignment Extension", 14, 25, "theatermasks.fill"),
            (5, "2 Min Session", "You completed a session", "Space Exploration", 2, 15, "mic.fill"),
        ]

        for s in sessionData {
            let date = cal.date(byAdding: .day, value: -s.daysAgo, to: Date()) ?? Date()
            let session = CompletedSession(
                id: UUID(),
                date: date,
                title: s.title,
                subtitle: s.subtitle,
                topic: s.topic,
                durationMinutes: s.duration,
                xp: s.xp,
                iconName: s.icon
            )
            dm.addSession(session)
        }
    }



    // MARK: - Activity History

    private func seedHistory() {
        let dm = HistoryDataModel.shared
        guard dm.getAllActivities().count <= 3 else { return }

        let activities: [(type: ActivityType, topic: String, duration: Int,
                          xp: Int, image: String, daysAgo: Int)] = [
            (.jam, "Climate Change", 2, 15, "Jam", 1),
            (.roleplay, "Behavioral Job Interview", 15, 25, "theatermasks.fill", 2),
            (.jam, "Dream Vacation", 2, 15, "Jam", 2),
            (.jam, "Favorite Movie", 2, 15, "Jam", 4),
            (.roleplay, "Campus Group Project Kickoff", 14, 25, "theatermasks.fill", 4),
            (.jam, "Space Exploration", 2, 15, "Jam", 5),
        ]

        for a in activities {
            let activity = Activity(
                type: a.type,
                date: Date().addingTimeInterval(Double(-a.daysAgo) * 86400),
                topic: a.topic,
                duration: a.duration,
                xpEarned: a.xp,
                isCompleted: true,
                title: a.type.rawValue,
                imageURL: a.image
            )
            dm.addActivity(activity)
        }
    }
}
