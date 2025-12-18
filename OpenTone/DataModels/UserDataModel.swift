import Foundation
final class UserDataModel {
    static let shared = UserDataModel()
    private let documentsDirectory: URL
    private let archiveURL: URL
    private var currentUser: User?
    private(set) var allUsers: [User] = []
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
    func getCurrentUser() -> User? {
        currentUser
    }
    func setCurrentUser(_ user: User) {
        currentUser = user
        persistCurrentUser()
    }
    func updateCurrentUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser
        persistCurrentUser()
    }
    func deleteCurrentUser(by id: UUID) {
        guard currentUser?.id == id else { return }
        currentUser = nil
        deletePersistedUser()
    }
    func getUser(by id: UUID) -> User? {
        allUsers.first { $0.id == id }
    }
    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        setCurrentUser(user)
    }
    func addCallRecordID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.callRecordIDs.append(id)
        setCurrentUser(user)
    }
    func addRoleplayID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.roleplayIDs.append(id)
        setCurrentUser(user)
    }
    func addJamSessionID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.jamSessionIDs.append(id)
        setCurrentUser(user)
    }
    func addFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.append(id)
        setCurrentUser(user)
    }
    func removeFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.removeAll { $0 == id }
        setCurrentUser(user)
    }
    private func loadCurrentUserFromDisk() {
        guard let data = try? Data(contentsOf: archiveURL) else { return }
        let decoder = JSONDecoder()
        currentUser = try? decoder.decode(User.self, from: data)
    }
    private func persistCurrentUser() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(currentUser) else { return }
        try? data.write(to: archiveURL, options: [.atomic])
    }
    private func deletePersistedUser() {
        try? FileManager.default.removeItem(at: archiveURL)
    }
    private func loadSampleUsersIfNeeded() {
        guard allUsers.isEmpty else { return }
        allUsers = loadSampleUsers()
        if currentUser == nil {
            currentUser = allUsers.last
            persistCurrentUser()
        }
    }
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

