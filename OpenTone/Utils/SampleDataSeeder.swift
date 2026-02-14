import Foundation

/// Seeds rich sample data for the 2 demo users so every screen in the app
/// has realistic content. Called once on quick-sign-in when no history exists.
@MainActor
final class SampleDataSeeder {

    static let shared = SampleDataSeeder()
    private init() {}

    private let seededKey = "SampleDataSeeder.hasSeeded"

    var hasSeeded: Bool {
        UserDefaults.standard.bool(forKey: seededKey)
    }

    /// Call this right after quick-sign-in to populate all data stores.
    func seedIfNeeded() {
        guard !hasSeeded else { return }
        seedStreakAndSessions()
        seedCallRecords()
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
            (0, "Roleplay", "You completed a session", "Grocery Shopping", 12, 25, "theatermasks.fill"),
            (1, "1 to 1 Call", "You completed a session", "Daily Conversation", 8, 20, "phone.fill"),
            (1, "2 Min Session", "You completed a session", "Climate Change", 2, 15, "mic.fill"),
            (2, "Roleplay", "You completed a session", "Job Interview", 15, 25, "theatermasks.fill"),
            (2, "2 Min Session", "You completed a session", "Dream Vacation", 2, 15, "mic.fill"),
            (3, "1 to 1 Call", "You completed a session", "Technology", 10, 20, "phone.fill"),
            (4, "2 Min Session", "You completed a session", "Favorite Movie", 2, 15, "mic.fill"),
            (4, "Roleplay", "You completed a session", "Hotel Booking", 14, 25, "theatermasks.fill"),
            (5, "2 Min Session", "You completed a session", "Space Exploration", 2, 15, "mic.fill"),
            (6, "1 to 1 Call", "You completed a session", "Music & Concerts", 7, 20, "phone.fill"),
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

    // MARK: - Call Records

    private func seedCallRecords() {
        let dm = CallRecordDataModel.shared
        guard dm.getAllCallRecords().isEmpty else { return }

        // Create some past call records using the second sample user as a partner
        let partnerID = UUID()  // a fictitious partner

        let records: [(name: String, avatar: String, bio: String,
                        daysAgo: Int, duration: TimeInterval)] = [
            ("Harshdeep Singh", "pp2", "On a journey to improve my Communication Skills", 1, 480),
            ("Ananya Patel", "pp1", "Love talking about travel and culture", 3, 600),
            ("Rohan Verma", "pp2", "Tech enthusiast and coder", 6, 420),
        ]

        for r in records {
            let record = CallRecord(
                participantID: partnerID,
                participantName: r.name,
                participantAvatarURL: r.avatar,
                participantBio: r.bio,
                participantInterests: [.technology, .travel],
                callDate: Date().addingTimeInterval(Double(-r.daysAgo) * 86400),
                duration: r.duration,
                userStatus: .offline
            )
            dm.addCallRecord(record)

            // Also register the record ID on the current user
            UserDataModel.shared.addCallRecordID(record.id)
        }
    }

    // MARK: - Activity History

    private func seedHistory() {
        let dm = HistoryDataModel.shared
        guard dm.getAllActivities().count <= 3 else { return }

        let activities: [(type: ActivityType, topic: String, duration: Int,
                          xp: Int, image: String, daysAgo: Int)] = [
            (.call, "Daily Conversation", 8, 20, "Call", 1),
            (.jam, "Climate Change", 2, 15, "Jam", 1),
            (.roleplay, "Job Interview", 15, 25, "JobInterview", 2),
            (.jam, "Dream Vacation", 2, 15, "Jam", 2),
            (.call, "Technology", 10, 20, "Call", 3),
            (.jam, "Favorite Movie", 2, 15, "Jam", 4),
            (.roleplay, "Hotel Booking", 14, 25, "HotelBooking", 4),
            (.jam, "Space Exploration", 2, 15, "Jam", 5),
            (.call, "Music & Concerts", 7, 20, "Call", 6),
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
