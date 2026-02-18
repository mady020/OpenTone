import Foundation

final class UserDataModel {

    static let shared = UserDataModel()


    private let documentsDirectory: URL
    private let usersArchiveURL: URL
    private let currentUserArchiveURL: URL


    private(set) var allUsers: [User] = []
    private var currentUser: User?


    private init() {
        self.documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        self.usersArchiveURL = documentsDirectory
            .appendingPathComponent("allUsers")
            .appendingPathExtension("json")

        self.currentUserArchiveURL = documentsDirectory
            .appendingPathComponent("currentUser")
            .appendingPathExtension("json")

        loadAllUsersFromDisk()
        loadCurrentUserFromDisk()
    }


    func getCurrentUser() -> User? {
        currentUser
    }

    func setCurrentUser(_ user: User) {
        upsertUser(user)
        currentUser = user
        persistCurrentUser()
    }

    func updateCurrentUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        upsertUser(updatedUser)
        currentUser = updatedUser
        persistCurrentUser()
    }

    func deleteCurrentUser() {
        currentUser = nil
        deletePersistedCurrentUser()
    }


    func registerUser(_ user: User) -> Bool {
        guard !allUsers.contains(where: { $0.email == user.email }) else {
            return false
        }

        allUsers.append(user)
        persistAllUsers()
        setCurrentUser(user)
        return true
    }

    func authenticate(email: String, password: String) -> User? {
        allUsers.first {
            $0.email == email && $0.password == password
        }
    }

    func getUser(by id: UUID) -> User? {
        allUsers.first { $0.id == id }
    }

    func getSampleUserForQuickSignIn() -> User? {
        // Returns the first sample user who has complete onboarding data
        // This user can be logged in directly without going through onboarding
        allUsers.first { user in
            user.confidenceLevel != nil && 
            user.englishLevel != nil &&
            user.interests != nil &&
            !user.interests!.isEmpty
        }
    }

    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        updateCurrentUser(user)
    }

    func addCallRecordID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.callRecordIDs.append(id)
        updateCurrentUser(user)
        SessionManager.shared.refreshSession()
    }

    func addRoleplayID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.roleplayIDs.append(id)
        updateCurrentUser(user)
        SessionManager.shared.refreshSession()
    }

    func addJamSessionID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.jamSessionIDs.append(id)
        updateCurrentUser(user)
        SessionManager.shared.refreshSession()
    }

    func addFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.append(id)
        updateCurrentUser(user)
    }

    func removeFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.removeAll { $0 == id }
        updateCurrentUser(user)
    }



    private func upsertUser(_ user: User) {
        if let index = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[index] = user
        } else {
            allUsers.append(user)
        }
        persistAllUsers()
    }


    private func persistAllUsers() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(allUsers) else { return }
        try? data.write(to: usersArchiveURL, options: [.atomic])
    }

    private func persistCurrentUser() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(currentUser) else { return }
        try? data.write(to: currentUserArchiveURL, options: [.atomic])
    }

    private func loadAllUsersFromDisk() {
        guard let data = try? Data(contentsOf: usersArchiveURL) else { return }
        let decoder = JSONDecoder()
        allUsers = (try? decoder.decode([User].self, from: data)) ?? []
    }

    private func loadCurrentUserFromDisk() {
        guard let data = try? Data(contentsOf: currentUserArchiveURL) else { return }
        let decoder = JSONDecoder()
        currentUser = try? decoder.decode(User.self, from: data)
    }

    private func deletePersistedCurrentUser() {
        try? FileManager.default.removeItem(at: currentUserArchiveURL)
    }



    

    
}

