import Foundation

@MainActor
class StreakDataModel {

    static let shared = StreakDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    ).first!
    private let archiveURL: URL
    private let dailyArchiveURL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("dailyProgress.json")
    
    private var streak: Streak?

    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("streak").appendingPathExtension(
            "json")
        loadStreak()
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
            streak = Streak(commitment : 0 , currentCount: 1, longestCount: 1, lastActiveDate: Date())
        }
        saveStreak()
    }

    func resetStreak() {
        if var currentStreak = streak {
            currentStreak.currentCount = 0
            streak = currentStreak
        } else {
            streak = Streak(commitment : 0 , currentCount: 0, longestCount: 0, lastActiveDate: nil)
        }
        saveStreak()
    }

    func deleteStreak() {
        streak = nil
        try? FileManager.default.removeItem(at: archiveURL)
    }

    private func loadStreak() {
        if let savedStreak = loadStreakFromDisk() {
            streak = savedStreak
        } else {
            streak = loadSampleStreak()
        }
    }

    private func loadStreakFromDisk() -> Streak? {
        guard let codedStreak = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Streak.self, from: codedStreak)
    }

    private func saveStreak() {
        guard let streak = streak else { return }
        let encoder = JSONEncoder()
        let codedStreak = try? encoder.encode(streak)
        try? codedStreak?.write(to: archiveURL)
    }
    
   

    private func loadSampleStreak() -> Streak {
        return Streak(commitment : 0 , currentCount: 0, longestCount: 0, lastActiveDate: nil)
    }
    func saveTodayProgress(minutes: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let progress = DailyProgress(date: today, minutesCompleted: minutes)

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(progress) {
            try? data.write(to: dailyArchiveURL)
        }
    }
    func loadYesterdayProgress() -> DailyProgress? {
        guard let data = try? Data(contentsOf: dailyArchiveURL),
              let saved = try? JSONDecoder().decode(DailyProgress.self, from: data)
        else { return nil }

        let yesterday =
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        if Calendar.current.isDate(saved.date, inSameDayAs: yesterday) {
            return saved
        }
        return nil
    }

}
