import Foundation
internal import PostgREST
import Supabase

@MainActor
class StreakDataModel {

    static let shared = StreakDataModel()

    private var sessions: [CompletedSession] = []
    private var streak: Streak?

    private init() {
        Task {
            await loadData()
        }
    }

    // MARK: - Streak Read/Write

    func getStreak() -> Streak? {
        return streak
    }

    func updateStreak(_ updatedStreak: Streak) {
        streak = updatedStreak
        Task {
            await saveStreakToSupabase()
        }
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
        Task { await saveStreakToSupabase() }
    }

    func resetStreak() {
        if var currentStreak = streak {
            currentStreak.currentCount = 0
            streak = currentStreak
        } else {
            streak = Streak(commitment: 0, currentCount: 0, longestCount: 0, lastActiveDate: nil)
        }
        Task { await saveStreakToSupabase() }
    }

    func deleteStreak() {
        streak = nil
        Task { await saveStreakToSupabase() }
    }

    // MARK: - Completed Sessions

    func addSession(_ session: CompletedSession) {
        sessions.append(session)
        Task {
            await insertCompletedSessionInSupabase(session)
        }
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
        Task {
            await insertCompletedSessionInSupabase(session)
        }
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

        Task { await saveStreakToSupabase() }
    }

    // MARK: - Supabase Operations

    private func loadData() async {
        await loadStreakFromSupabase()
        await loadSessionsFromSupabase()
    }

    private func loadStreakFromSupabase() async {
        guard let user = UserDataModel.shared.getCurrentUser() else {
            streak = Streak(commitment: 0, currentCount: 0, longestCount: 0, lastActiveDate: nil)
            return
        }

        // Streak is stored as columns on the users table
        streak = user.streak ?? Streak(commitment: 0, currentCount: 0, longestCount: 0, lastActiveDate: nil)
    }

    private func saveStreakToSupabase() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id,
              let streak = streak else { return }

        struct StreakUpdate: Codable {
            let streakCommitment: Int
            let streakCurrent: Int
            let streakLongest: Int
            let streakLastActive: Date?

            enum CodingKeys: String, CodingKey {
                case streakCommitment = "streak_commitment"
                case streakCurrent    = "streak_current"
                case streakLongest    = "streak_longest"
                case streakLastActive = "streak_last_active"
            }
        }

        let update = StreakUpdate(
            streakCommitment: streak.commitment,
            streakCurrent: streak.currentCount,
            streakLongest: streak.longestCount,
            streakLastActive: streak.lastActiveDate
        )

        do {
            try await supabase
                .from(SupabaseTable.users)
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            print("❌ Failed to save streak: \(error.localizedDescription)")
        }
    }

    private func loadSessionsFromSupabase() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else {
            sessions = []
            return
        }

        do {
            let rows: [CompletedSessionRow] = try await supabase
                .from(SupabaseTable.completedSessions)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("date", ascending: false)
                .execute()
                .value
            sessions = rows.map { $0.toCompletedSession() }
        } catch {
            print("❌ Failed to load completed sessions: \(error.localizedDescription)")
            sessions = []
        }
    }

    private func insertCompletedSessionInSupabase(_ session: CompletedSession) async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let row = CompletedSessionRow(from: session, userId: userId)
            try await supabase
                .from(SupabaseTable.completedSessions)
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to insert completed session: \(error.localizedDescription)")
        }
    }
}
