import Foundation

@MainActor
final class SessionManager {

    static let shared = SessionManager()

    private(set) var currentUser: User?
    private var activities: [Activity] = []

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var lastUnfinishedActivity: Activity? {
        activities
            .sorted { $0.date > $1.date }
            .first { !$0.isCompleted }
    }

    private init() {
        Task { @MainActor in
            await restoreSessionFromSupabase()
        }
    }

    func restoreSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }

    func restoreSessionFromSupabase() async {
        _ = await SupabaseAuth.hasActiveSession()
        refreshSession()
    }

    func login(user: User) {
        currentUser = user
        UserDataModel.shared.setCurrentUser(user)
        reloadAllDataModels()
    }

    func logout() {
        Task { @MainActor in
            await logoutAsync()
        }
    }

    func logoutAsync() async {
        let outgoingUser = currentUser

        do {
            try await SupabaseAuth.signOut()
        } catch {
            print("❌ Supabase sign out failed: \(error.localizedDescription)")
        }

        clearUserScopedDefaults(for: outgoingUser)
        clearUserScopedFiles(for: outgoingUser)
        AudioManager.shared.resetForLogout()

        currentUser = nil
        UserDataModel.shared.deleteCurrentUser()
        // Clear cached speech coaching data so the next user starts fresh
        UserDefaults.standard.removeObject(forKey: "opentone.lastWpmDelta")
        reloadAllDataModels()
    }

    private func clearUserScopedDefaults(for user: User?) {
        guard let userId = user?.id.uuidString else { return }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "opentone.feedback.profile.\(userId)")
        defaults.removeObject(forKey: "opentone.feedback.recentSuggestions.\(userId)")
        defaults.removeObject(forKey: "SampleDataSeeder.hasSeeded.\(userId)")

        let dailyGoalPrefix = "opentone.dailyGoalAchievement.\(userId)."
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(dailyGoalPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func clearUserScopedFiles(for user: User?) {
        guard let avatarName = user?.avatar,
              avatarName.hasPrefix("custom_avatar_") else {
            return
        }

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let avatarURL = documentsURL.appendingPathComponent(avatarName)
        if FileManager.default.fileExists(atPath: avatarURL.path) {
            try? FileManager.default.removeItem(at: avatarURL)
        }
    }

    func hasAuthenticatedAPIAccess() async -> Bool {
        await SupabaseAuth.accessToken() != nil
    }

    /// Tells every data-model singleton to drop cached data and reload
    /// for the current user. Must be called on every user change.
    private func reloadAllDataModels() {
        StreakDataModel.shared.reloadForCurrentUser()
        HistoryDataModel.shared.reloadForCurrentUser()
        JamSessionDataModel.shared.reloadForCurrentUser()
        RoleplaySessionDataModel.shared.reloadForCurrentUser()
        CallRecordDataModel.shared.reloadForCurrentUser()
        activities = []
    }

    func refreshSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }

    func updateSessionUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser
        UserDataModel.shared.updateCurrentUser(updatedUser)
    }

    func setActivities(_ activities: [Activity]) {
        self.activities = activities
    }

    func addActivity(_ activity: Activity) {
        activities.append(activity)
    }

    func markActivityCompleted(_ id: UUID) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }

        let activity = activities[index]
        activities[index] = Activity(
            type: activity.type,
            date: activity.date,
            topic: activity.topic,
            duration: activity.duration,
            xpEarned: activity.xpEarned,
            isCompleted: true,
            title: activity.title,
            imageURL: activity.imageURL,
            roleplaySession: activity.roleplaySession,
            feedback: activity.feedback
        )
    }
}
