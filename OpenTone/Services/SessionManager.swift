

import Foundation
final class SessionManager {
    static let shared = SessionManager()
    private(set) var currentUser: User?
    
    private var activities: [Activity] = []

       var lastUnfinishedActivity: Activity? {
           activities
               .sorted { $0.date > $1.date }
               .first { !$0.isCompleted }
       }
    var isLoggedIn: Bool {
        currentUser != nil
    }
    private init() {
        restoreSession()
    }
    func restoreSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }
    func login(user: User) {
        UserDataModel.shared.setCurrentUser(user)
        currentUser = user
    }
    func logout() {
        guard let user = currentUser else { return }
        UserDataModel.shared.deleteCurrentUser(by: user.id)
        currentUser = nil
    }
    func refreshSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }
    func updateSessionUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        UserDataModel.shared.updateCurrentUser(updatedUser)
        currentUser = updatedUser
    }

    func setActivities(_ activities: [Activity]) {
        self.activities = activities
    }

    func addActivity(_ activity: Activity) {
        activities.append(activity)
    }

    func markActivityCompleted(_ id: UUID) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        activities[index] = Activity(
            type: activities[index].type,
            date: activities[index].date,
            topic: activities[index].topic,
            duration: activities[index].duration,
            xpEarned: activities[index].xpEarned,
            isCompleted: true,
            title: activities[index].title,
            imageURL: activities[index].imageURL,
            roleplaySession: activities[index].roleplaySession,
            feedback: activities[index].feedback
        )
    }

}
