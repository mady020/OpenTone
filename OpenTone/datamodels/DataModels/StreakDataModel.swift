import Foundation

@MainActor
class StreakDataModel {

    static let shared = StreakDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    ).first!
    private let archiveURL: URL

    private var streak: Streak?

    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("streak").appendingPathExtension(
            "plist")
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
        let propertyListDecoder = PropertyListDecoder()
        return try? propertyListDecoder.decode(Streak.self, from: codedStreak)
    }

    private func saveStreak() {
        guard let streak = streak else { return }
        let propertyListEncoder = PropertyListEncoder()
        let codedStreak = try? propertyListEncoder.encode(streak)
        try? codedStreak?.write(to: archiveURL)
    }
    
   

    private func loadSampleStreak() -> Streak {
        return Streak(commitment : 0 , currentCount: 0, longestCount: 0, lastActiveDate: nil)
    }
}
