import Foundation

@MainActor
class StreakDataModel {

    static let shared = StreakDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    ).first!
    private let streakURL: URL
    private let sessionsURL: URL

    private var sessions: [CompletedSession] = []
    private var streak: Streak?

    private init() {
        streakURL = documentsDirectory.appendingPathComponent("streak.json")
        sessionsURL = documentsDirectory.appendingPathComponent("sessions.json")
        loadStreak()
        loadSessions()
    }
    func getStreak() -> Streak? {
        return streak
    }

    func updateStreak(_ updatedStreak: Streak) {
        streak = updatedStreak
        saveStreak()
    }

    func incrementStreak() {
        if var currentStreak = streak {
            currentStreak.currentCount += 1
            if currentStreak.currentCount > currentStreak.longestCount {
                currentStreak.longestCount = currentStreak.currentCount
            }
            currentStreak.lastActiveDate = Date()
            streak = currentStreak
        } else {
            streak = Streak(commitment: 0, currentCount: 1, longestCount: 1, lastActiveDate: Date())
        }
        saveStreak()
    }

    func resetStreak() {
        if var currentStreak = streak {
            currentStreak.currentCount = 0
            streak = currentStreak
        } else {
            streak = Streak(commitment: 0, currentCount: 0, longestCount: 0, lastActiveDate: nil)
        }
        saveStreak()
    }

    func deleteStreak() {
        streak = nil
        try? FileManager.default.removeItem(at: streakURL)
    }

    private func loadStreak() {
        if let data = try? Data(contentsOf: streakURL),
           let decoded = try? JSONDecoder().decode(Streak.self, from: data) {
            streak = decoded
        } else {
            streak = Streak(commitment: 0, currentCount: 0, longestCount: 0, lastActiveDate: nil)
        }
    }

    private func saveStreak() {
        guard let streak = streak else { return }
        if let data = try? JSONEncoder().encode(streak) {
            try? data.write(to: streakURL)
        }
    }
    private func loadSessions() {
        guard let data = try? Data(contentsOf: sessionsURL),
              let decoded = try? JSONDecoder().decode([CompletedSession].self, from: data)
        else {
            sessions = []
            return
        }
        sessions = decoded
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: sessionsURL)
        }
    }

    /// Append a pre-built session (used by SampleDataSeeder)
    func addSession(_ session: CompletedSession) {
        sessions.append(session)
        saveSessions()
    }

    func logSession(title: String,
                    subtitle: String,
                    topic: String,
                    durationMinutes: Int,
                    xp: Int,
                    iconName: String) {
        let session = CompletedSession(
            id: UUID(),
            date: Date(),
            title: title,
            subtitle: subtitle,
            topic: topic,
            durationMinutes: durationMinutes,
            xp: xp,
            iconName: iconName
        )

        sessions.append(session)
        saveSessions()
        updateStreakForToday()
    }

    func sessions(for date: Date) -> [CompletedSession] {
        let start = Calendar.current.startOfDay(for: date)
        return sessions.filter { Calendar.current.isDate($0.date, inSameDayAs: start) }
    }

    func totalMinutes(for date: Date) -> Int {
        return sessions(for: date).reduce(0) { $0 + $1.durationMinutes }
    }

    func weeklyStats(referenceDate: Date = Date()) -> (totalMinutes: Int, bestDay: Date?) {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else {
            return (0, nil)
        }

        var totalsByDay: [Date: Int] = [:]

        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: weekStart) else { continue }
            totalsByDay[calendar.startOfDay(for: day)] = totalMinutes(for: day)
        }

        let totalWeek = totalsByDay.values.reduce(0, +)
        let bestDay = totalsByDay.max { $0.value < $1.value }?.key

        return (totalWeek, bestDay)
    }
    func updateStreakForToday() {
        let today = Calendar.current.startOfDay(for: Date())

        if var streak = streak {
            if let lastDate = streak.lastActiveDate {
                let lastDay = Calendar.current.startOfDay(for: lastDate)
                let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

                if diff == 0 {
                    return // Already counted today
                } else if diff == 1 {
                    streak.currentCount += 1
                } else {
                    streak.currentCount = 1
                }
            } else {
                streak.currentCount = 1
            }

            streak.longestCount = max(streak.longestCount, streak.currentCount)
            streak.lastActiveDate = today
            self.streak = streak
        } else {
            streak = Streak(commitment: 0, currentCount: 1, longestCount: 1, lastActiveDate: today)
        }

        saveStreak()
    }
    
    func resetAllPracticeData() {
        UserDefaults.standard.removeObject(forKey: "dailyMinutes")
        UserDefaults.standard.removeObject(forKey: "weeklyMinutes")
    }

    func buildProgressCellData() -> ProgressCellData {

        let today = Calendar.current.startOfDay(for: Date())

        let todayMinutes = totalMinutes(for: today)

        let commitment = streak?.commitment ?? 0

        // Monday-based weekly minutes
        var weekly: [Int] = []
        let calendar = Calendar.current
        
        // Find the most recent Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let monday = calendar.date(from: components) else {
            return ProgressCellData(streakDays: streak?.currentCount ?? 0, todayMinutes: todayMinutes, dailyGoalMinutes: commitment, weeklyMinutes: Array(repeating: 0, count: 7))
        }

        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: monday) {
                weekly.append(totalMinutes(for: day))
            } else {
                weekly.append(0)
            }
        }

        return ProgressCellData(
            streakDays: streak?.currentCount ?? 0,
            todayMinutes: todayMinutes,
            dailyGoalMinutes: commitment,
            weeklyMinutes: weekly
        )
    }

}
