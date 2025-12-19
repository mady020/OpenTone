import Foundation

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
        restoreSession()
    }

   

    func restoreSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }

    func login(user: User) {
        currentUser = user
    }

    func logout() {
        currentUser = nil
//        UserDataModel.shared.deleteCurrentUser()
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

