import Foundation

@MainActor
class UserDataModel {

    static let shared = UserDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private let archiveURL: URL

    // The only user this app manages
    private var currentUser: User?
    var allUsers: [User] = []
    private init() {
        archiveURL =
            documentsDirectory
            .appendingPathComponent("currentUser")
            .appendingPathExtension("plist")

         loadUser()
        allUsers = loadSampleUser()
    }

    /// Returns the currently authenticated/active user.
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func getUser(by id: UUID) -> User? {
        return allUsers.first(where: { $0.id == id })
    }

    /// Saves the given user as the current active user.
    /// Used when creating a profile or editing profile settings.
    func saveCurrentUser(_ user: User) {
        currentUser = user
        saveUser()
    }

    /// Updates the existing current user with modified fields.
    func updateUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser
        saveUser()
    }

    /// Deletes the user permanently from disk.
    func deleteUser(by id: UUID) {
        if currentUser?.id == id {
            currentUser = nil
            saveUser()
        }
    }

    /// Updates the lastSeen timestamp to mark the user as "online".
    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        saveCurrentUser(user)
    }

    /// Adds a call record ID to the current user.
    func addCallRecordID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.callRecordIDs.append(id)
        saveCurrentUser(user)
    }

    /// Adds a roleplay session ID to the current user.
    func addRoleplayID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.roleplayIDs.append(id)
        saveCurrentUser(user)
    }

    /// Adds a jam session ID to the current user.
    func addJamSessionID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.jamSessionIDs.append(id)
        saveCurrentUser(user)
    }

    /// Adds a friend to the user's friend list.
    func addFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.append(id)
        saveCurrentUser(user)
    }

    /// Returns the index of a friend in the friend list if it exists.
    func getFriendIndex(from id: UUID) -> Int? {
        guard let user = currentUser else { return nil }
        return user.friendsIDs.firstIndex(of: id)
    }

    /// Deletes a friend from the user's friend list.
    func deleteFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        guard let index = getFriendIndex(from: id) else { return }
        user.friendsIDs.remove(at: index)
        saveCurrentUser(user)
    }

    /// Loads the current user from disk (if exists), otherwise loads a sample.
    private func loadUser() {
        if let data = try? Data(contentsOf: archiveURL) {
            let decoder = PropertyListDecoder()
            currentUser = try? decoder.decode(User.self, from: data)
        }

        // If still nil, load a sample user for first-time app usage
        if currentUser == nil {
            currentUser = loadSampleUser().last
            saveUser()
        }
    }

    /// Saves the current user to disk.
    private func saveUser() {
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(currentUser) {
            try? data.write(to: archiveURL)
        }
    }

    /// A default user for first app launch (MVP).
    private func loadSampleUser() -> [User] {
        return [User(
            name: "John Doe",
            email: "john@example.com",
            age: 25,
            gender: .male,
            bio: "Learning English",
            englishLevel: .beginner,
            interests: [],
            currentPlan: .free,
            avatar: nil,
            streak: nil,
            lastSeen: nil,
            callRecordIDs: [],
            roleplayIDs: [],
            jamSessionIDs: [],
            friends: []
        ) , User(
            name: "John Doe",
            email: "john@example.com",
            age: 25,
            gender: .male,
            bio: "Learning English",
            englishLevel: .beginner,
            interests: [.technology , .art , .food],
            currentPlan: .free,
            avatar: nil,
            streak: nil,
            lastSeen: nil,
            callRecordIDs: [],
            roleplayIDs: [],
            jamSessionIDs: [],
            friends: []
        )]
    }
}
