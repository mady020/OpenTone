//
//  decides.swift
//  OpenTone
//
//  Created by M S on 18/12/25.
//


import Foundation

/// Manages the authentication/session state of the app.
/// This class decides WHO is logged in, not HOW users are stored.
/// Persistence is delegated to UserDataModel.
final class SessionManager {

    /// Shared global session instance
    static let shared = SessionManager()

    /// Currently logged-in user
    private(set) var currentUser: User?
    
    private var activities: [Activity] = []

       // MARK: - Activity helpers

       var lastUnfinishedActivity: Activity? {
           activities
               .sorted { $0.date > $1.date }
               .first { !$0.isCompleted }
       }

    /// Indicates whether a user session exists
    var isLoggedIn: Bool {
        currentUser != nil
    }

    /// Private initializer to enforce singleton usage
    private init() {
        restoreSession()
    }

    // MARK: - Session Lifecycle

    /// Restores the user session from persisted storage
    /// Called automatically when the app launches
    func restoreSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }

    /// Starts a new session with the given user
    /// Use this after successful login or signup
    func login(user: User) {
        UserDataModel.shared.setCurrentUser(user)
        currentUser = user
    }

    /// Ends the current session and clears persisted data
    func logout() {
        guard let user = currentUser else { return }
        UserDataModel.shared.deleteCurrentUser(by: user.id)
        currentUser = nil
    }

    // MARK: - Session Sync

    /// Refreshes the in-memory session user from disk
    /// Useful after background updates or app resume
    func refreshSession() {
        currentUser = UserDataModel.shared.getCurrentUser()
    }

    /// Updates the current session user and persists it
    /// Use when user profile data changes
    func updateSessionUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        UserDataModel.shared.updateCurrentUser(updatedUser)
        currentUser = updatedUser
    }
    
    
    // MARK: - Activities

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
