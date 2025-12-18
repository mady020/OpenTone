import Foundation

/// Handles persistence and mutation of User data.
/// This class is responsible ONLY for storing, loading,
/// and updating User objects. It does NOT manage login/session state.
final class UserDataModel {

    /// Shared singleton instance
    static let shared = UserDataModel()

    /// App documents directory
    private let documentsDirectory: URL

    /// File URL for persisting the current user
    private let archiveURL: URL

    /// User loaded from disk (if any)
    private var currentUser: User?

    /// In-memory list of users (used for local/sample data)
    private(set) var allUsers: [User] = []

    /// Private initializer to enforce singleton
    private init() {
        self.documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        self.archiveURL = documentsDirectory
            .appendingPathComponent("currentUser")
            .appendingPathExtension("json")

        loadCurrentUserFromDisk()
        loadSampleUsersIfNeeded()
    }

    // MARK: - Current User Access

    /// Returns the currently persisted user, if available
    func getCurrentUser() -> User? {
        currentUser
    }

    /// Sets and persists a user as the current user
    func setCurrentUser(_ user: User) {
        currentUser = user
        persistCurrentUser()
    }

    /// Updates the current user if the IDs match
    func updateCurrentUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser
        persistCurrentUser()
    }

    /// Deletes the current user if the ID matches
    func deleteCurrentUser(by id: UUID) {
        guard currentUser?.id == id else { return }
        currentUser = nil
        deletePersistedUser()
    }

    // MARK: - User Lookup

    /// Returns a user from the local user list by ID
    func getUser(by id: UUID) -> User? {
        allUsers.first { $0.id == id }
    }

    // MARK: - User Mutations

    /// Updates the lastSeen timestamp of the current user
    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        setCurrentUser(user)
    }

    /// Adds a call record ID to the current user
    func addCallRecordID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.callRecordIDs.append(id)
        setCurrentUser(user)
    }

    /// Adds a roleplay ID to the current user
    func addRoleplayID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.roleplayIDs.append(id)
        setCurrentUser(user)
    }

    /// Adds a jam session ID to the current user
    func addJamSessionID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.jamSessionIDs.append(id)
        setCurrentUser(user)
    }

    /// Adds a friend ID to the current user
    func addFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.append(id)
        setCurrentUser(user)
    }

    /// Removes a friend ID from the current user
    func removeFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.removeAll { $0 == id }
        setCurrentUser(user)
    }

    // MARK: - Persistence

    /// Loads the persisted user from disk
    private func loadCurrentUserFromDisk() {
        guard let data = try? Data(contentsOf: archiveURL) else { return }
        let decoder = JSONDecoder()
        currentUser = try? decoder.decode(User.self, from: data)
    }

    /// Persists the current user to disk
    private func persistCurrentUser() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(currentUser) else { return }
        try? data.write(to: archiveURL, options: [.atomic])
    }

    /// Deletes the persisted user file
    private func deletePersistedUser() {
        try? FileManager.default.removeItem(at: archiveURL)
    }

    // MARK: - Sample Data

    /// Loads sample users into memory for local development
    private func loadSampleUsersIfNeeded() {
        guard allUsers.isEmpty else { return }
        allUsers = loadSampleUsers()

        // If no persisted user exists, assign a default sample user
        if currentUser == nil {
            currentUser = allUsers.last
            persistCurrentUser()
        }
    }

    /// Creates sample users matching the User model
    private func loadSampleUsers() -> [User] {
        return [

            User(
                name: "Madhav Sharma",
                email: "madhav@opentone.com",
                password: "madhav123",
                country: Country(name: "India", code: "🇮🇳"),
                age: 20,
                gender: .male,
                bio: "Learning to communicate every day and loving the progress.",
                englishLevel: .beginner,
                confidenceLevel: ConfidenceOption(title: "Very Nervous", emoji: "🥺"),
                interests: [
                    InterestItem(title: "Public Speaking", symbol: "🎤"),
                    InterestItem(title: "Travel", symbol: "✈️")
                ],
                currentPlan: .free,
                avatar: "pp1",
                streak: nil,
                lastSeen: Date().addingTimeInterval(-120), // offline
                callRecordIDs: [],
                roleplayIDs: [],
                jamSessionIDs: [],
                friends: [],
                goal: 10
            ),

            User(
                name: "Harshdeep Singh",
                email: "harsh@opentone.com",
                password: "harsh123",
                country: Country(name: "India", code: "🇮🇳"),
                age: 19,
                gender: .male,
                bio: "On a journey to improve my Communication Skills",
                englishLevel: .beginner,
                interests: [
                    InterestItem(title: "Casual Conversation", symbol: "💬"),
                    InterestItem(title: "Interview Practice", symbol: "🧑‍💼")
                ],
                currentPlan: .free,
                avatar: "pp2",
                streak: nil,
                lastSeen: Date(), // online
                callRecordIDs: [],
                roleplayIDs: [],
                jamSessionIDs: [],
                friends: [],
                goal: 15
            )

        ]
    }

}

