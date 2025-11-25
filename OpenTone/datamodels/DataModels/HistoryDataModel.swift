import Foundation

@MainActor
class HistoryDataModel {

    static let shared = HistoryDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private let archiveURL: URL

    private var activities: [Activity] = []

    private init() {
        archiveURL =
            documentsDirectory
            .appendingPathComponent("history")
            .appendingPathExtension("json")

        loadHistory()
    }

    /// Returns all activities for a specific calendar day.
    func getActivities(for date: Date) -> [Activity] {

        let calendar = Calendar.current

        return activities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }

    /// Adds a new activity to history.
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        saveHistory()
    }

    func logActivity(
        type: ActivityType,
        title: String,
        topic: String,
        duration: Int,
        imageURL: String,
        xpEarned: Int = 5,
        isCompleted: Bool = true
    ) {
        let activity = Activity(
            type: type,
            date: Date(),
            topic: topic,
            duration: duration,
            xpEarned: xpEarned,
            isCompleted: isCompleted,
            title: title,
            imageURL: imageURL
        )

        addActivity(activity)
    }

    /// Filters history based on activity type (call, jam, roleplay, etc.)
    func searchHistory(by type: ActivityType) -> [Activity] {
        return activities.filter { $0.type == type }
    }

    /// Returns all activities sorted by date (newest first).
    func getAllActivities() -> [Activity] {
        return activities.sorted { $0.date > $1.date }
    }

    private func loadHistory() {
        if let savedActivities = loadHistoryFromDisk() {
            activities = savedActivities
        } else {
            activities = loadSampleActivities()
        }
    }

    private func loadHistoryFromDisk() -> [Activity]? {
        guard let codedActivities = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([Activity].self, from: codedActivities)
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(activities) {
            try? data.write(to: archiveURL)
        }
    }

    private func loadSampleActivities() -> [Activity] {
        let activity1 = Activity(
            type: .call,
            date: Date().addingTimeInterval(-86400),
            topic: "Daily Conversation",
            duration: 5,
            xpEarned: 10,
            isCompleted: true,
            title: "Call Session",
            imageURL: "call_sample"
        )

        let activity2 = Activity(
            type: .jam,
            date: Date().addingTimeInterval(-172800),
            topic: "Space Exploration",
            duration: 3,
            xpEarned: 6,
            isCompleted: true,
            title: "Jam Session",
            imageURL: "jam_sample"
        )

        let activity3 = Activity(
            type: .roleplay,
            date: Date().addingTimeInterval(-259200),
            topic: "Interview Practice",
            duration: 4,
            xpEarned: 12,
            isCompleted: true,
            title: "Roleplay",
            imageURL: "roleplay_sample"
        )

        return [activity1, activity2, activity3]
    }
}
