import Foundation
internal import PostgREST
import Supabase

@MainActor
class HistoryDataModel {

    static let shared = HistoryDataModel()

    private var activities: [Activity] = []

    private init() {
        Task {
            await loadHistory()
        }
    }

    // MARK: - Read

    func getActivities(for date: Date) -> [Activity] {
        let calendar = Calendar.current
        return activities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }

    func searchHistory(by type: ActivityType) -> [Activity] {
        return activities.filter { $0.type == type }
    }

    func getAllActivities() -> [Activity] {
        return activities.sorted { $0.date > $1.date }
    }

    // MARK: - Write

    func addActivity(_ activity: Activity) {
        activities.append(activity)

        Task {
            await insertActivityInSupabase(activity)
        }
    }

    func logActivity(
        type: ActivityType,
        title: String,
        topic: String,
        duration: Int,
        imageURL: String,
        xpEarned: Int = 5,
        isCompleted: Bool = true,
        scenarioId: UUID? = nil
    ) {
        let activity = Activity(
            type: type,
            date: Date(),
            topic: topic,
            duration: duration,
            xpEarned: xpEarned,
            isCompleted: isCompleted,
            title: title,
            imageURL: imageURL,
            scenarioId: scenarioId
        )
        addActivity(activity)
    }

    func clearHistory() {
        activities = []
        Task {
            await deleteAllActivitiesFromSupabase()
        }
    }

    // MARK: - Supabase Operations

    private func loadHistory() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else {
            activities = loadSampleActivities()
            return
        }

        do {
            let rows: [ActivityRow] = try await supabase
                .from(SupabaseTable.activities)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("date", ascending: false)
                .execute()
                .value
            activities = rows.map { $0.toActivity() }

            if activities.isEmpty {
                activities = loadSampleActivities()
            }
        } catch {
            print("❌ Failed to load activities: \(error.localizedDescription)")
            activities = loadSampleActivities()
        }
    }

    private func insertActivityInSupabase(_ activity: Activity) async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let row = ActivityRow(from: activity, userId: userId)
            try await supabase
                .from(SupabaseTable.activities)
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to insert activity: \(error.localizedDescription)")
        }
    }

    private func deleteAllActivitiesFromSupabase() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            try await supabase
                .from(SupabaseTable.activities)
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            print("❌ Failed to clear activities: \(error.localizedDescription)")
        }
    }

    // MARK: - Sample Data

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
