import Foundation
internal import PostgREST
import Supabase

final class UserDataModel {

    static let shared = UserDataModel()

    // In-memory cache
    private(set) var allUsers: [User] = []
    private var currentUser: User?

    /// Key for persisting the current user's UUID across launches.
    private let currentUserIDKey = "currentUserID"

    private init() {
        // Kick off an async load — callers should observe `allUsers` after this completes.
        Task { @MainActor in
            await loadAllUsersFromSupabase()
            await restoreCurrentUser()
        }
    }

    // MARK: - Current User

    func getCurrentUser() -> User? {
        currentUser
    }

    func setCurrentUser(_ user: User) {
        currentUser = user
        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserIDKey)
    }

    func updateCurrentUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser

        // Update in-memory cache
        if let index = allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
            allUsers[index] = updatedUser
        }

        // Persist to Supabase
        Task {
            await updateUserInSupabase(updatedUser)
        }
    }

    func deleteCurrentUser() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserIDKey)
    }

    // MARK: - Registration & Auth

    func registerUser(_ user: User) -> Bool {
        guard !allUsers.contains(where: { $0.email == user.email }) else {
            return false
        }

        allUsers.append(user)
        setCurrentUser(user)

        Task {
            await insertUserInSupabase(user)
        }
        return true
    }

    func authenticate(email: String, password: String) -> User? {
        // Try local cache first
        if let cached = allUsers.first(where: { $0.email == email && $0.password == password }) {
            return cached
        }
        return nil
    }

    /// Async version that queries Supabase directly.
    func authenticateAsync(email: String, password: String) async -> User? {
        do {
            let rows: [UserRow] = try await supabase
                .from(SupabaseTable.users)
                .select()
                .eq("email", value: email)
                .eq("password", value: password)
                .execute()
                .value
            guard let row = rows.first else { return nil }
            let user = row.toUser()
            // Update cache
            await MainActor.run {
                if !self.allUsers.contains(where: { $0.id == user.id }) {
                    self.allUsers.append(user)
                }
            }
            return user
        } catch {
            print("❌ Supabase auth error: \(error.localizedDescription)")
            return nil
        }
    }

    func getUser(by id: UUID) -> User? {
        allUsers.first { $0.id == id }
    }

    func getSampleUserForQuickSignIn() -> User? {
        allUsers.first { user in
            user.confidenceLevel != nil &&
            user.englishLevel != nil &&
            user.interests != nil &&
            !user.interests!.isEmpty
        }
    }

    // MARK: - Field Updaters

    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        updateCurrentUser(user)
    }

    func addCallRecordID(_ id: UUID) {
        // No longer stored on user — call_records table has user_id FK.
        // Keep SessionManager refresh for UI updates.
        SessionManager.shared.refreshSession()
    }

    func addRoleplayID(_ id: UUID) {
        SessionManager.shared.refreshSession()
    }

    func addJamSessionID(_ id: UUID) {
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

    // MARK: - Supabase Operations

    private func loadAllUsersFromSupabase() async {
        do {
            let rows: [UserRow] = try await supabase
                .from(SupabaseTable.users)
                .select()
                .execute()
                .value
            let users = rows.map { $0.toUser() }
            await MainActor.run {
                self.allUsers = users
            }
        } catch {
            print("❌ Failed to load users from Supabase: \(error.localizedDescription)")
            // Fallback: seed sample users if the table is empty
            await seedSampleUsersIfNeeded()
        }
    }

    private func restoreCurrentUser() async {
        guard let idString = UserDefaults.standard.string(forKey: currentUserIDKey),
              let id = UUID(uuidString: idString) else {
            // No stored session — try to pick a sample user
            await MainActor.run {
                self.currentUser = self.allUsers.last
            }
            return
        }

        // Try local cache
        if let cached = allUsers.first(where: { $0.id == id }) {
            await MainActor.run { self.currentUser = cached }
            return
        }

        // Fetch from Supabase
        do {
            let rows: [UserRow] = try await supabase
                .from(SupabaseTable.users)
                .select()
                .eq("id", value: id.uuidString)
                .execute()
                .value
            if let row = rows.first {
                let user = row.toUser()
                await MainActor.run {
                    self.currentUser = user
                    if !self.allUsers.contains(where: { $0.id == user.id }) {
                        self.allUsers.append(user)
                    }
                }
            }
        } catch {
            print("❌ Failed to restore user from Supabase: \(error.localizedDescription)")
        }
    }

    private func insertUserInSupabase(_ user: User) async {
        do {
            let row = UserRow(from: user)
            try await supabase
                .from(SupabaseTable.users)
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to insert user: \(error.localizedDescription)")
        }
    }

    private func updateUserInSupabase(_ user: User) async {
        do {
            let row = UserRow(from: user)
            try await supabase
                .from(SupabaseTable.users)
                .update(row)
                .eq("id", value: user.id.uuidString)
                .execute()
        } catch {
            print("❌ Failed to update user: \(error.localizedDescription)")
        }
    }

    // MARK: - Sample Data Seeding

    private func seedSampleUsersIfNeeded() async {
        // Check if table is actually empty
        do {
            let rows: [UserRow] = try await supabase
                .from(SupabaseTable.users)
                .select()
                .limit(1)
                .execute()
                .value
            guard rows.isEmpty else { return }
        } catch {
            // If we can't even query, don't seed
            return
        }

        let sampleUsers = loadSampleUsers()
        for user in sampleUsers {
            await insertUserInSupabase(user)
        }

        await MainActor.run {
            self.allUsers = sampleUsers
            if self.currentUser == nil {
                self.currentUser = sampleUsers.last
                if let id = sampleUsers.last?.id {
                    UserDefaults.standard.set(id.uuidString, forKey: self.currentUserIDKey)
                }
            }
        }
    }

    private func loadSampleUsers() -> [User] {
        [
            User(
                name: "Madhav Sharma",
                email: "madhav@opentone.com",
                password: "Madhav@123",
                country: Country(name: "India", code: "IN"),
                age: 20,
                gender: .male,
                bio: "Learning to communicate every day and loving the progress. Passionate about public speaking and making new connections.",
                englishLevel: .beginner,
                confidenceLevel: ConfidenceOption(title: "Very Nervous", emoji: "🥺"),
                interests: [
                    InterestItem(title: "Public Speaking", symbol: "🎤"),
                    InterestItem(title: "Travel", symbol: "✈️"),
                    InterestItem(title: "Technology", symbol: "💻"),
                    InterestItem(title: "Movies", symbol: "🎬"),
                ],
                currentPlan: .free,
                avatar: "pp1",
                streak: Streak(commitment: 10, currentCount: 5, longestCount: 8, lastActiveDate: Date()),
                lastSeen: Date().addingTimeInterval(-120),
                callRecordIDs: [],
                roleplayIDs: [],
                jamSessionIDs: [],
                friends: [],
                goal: 10
            ),
            User(
                name: "Harshdeep Singh",
                email: "harsh@opentone.com",
                password: "Harsh@123",
                country: Country(name: "India", code: "IN"),
                age: 19,
                gender: .male,
                bio: "On a journey to improve my Communication Skills. Love meeting people and exploring new cultures.",
                englishLevel: .intermediate,
                confidenceLevel: ConfidenceOption(title: "Somewhat Confident", emoji: "😊"),
                interests: [
                    InterestItem(title: "Casual Conversation", symbol: "💬"),
                    InterestItem(title: "Interview Practice", symbol: "🧑‍💼"),
                    InterestItem(title: "Music", symbol: "🎵"),
                ],
                currentPlan: .free,
                avatar: "pp2",
                streak: Streak(commitment: 15, currentCount: 3, longestCount: 5, lastActiveDate: Date().addingTimeInterval(-86400)),
                lastSeen: Date(),
                callRecordIDs: [],
                roleplayIDs: [],
                jamSessionIDs: [],
                friends: [],
                goal: 15
            )
        ]
    }
}
