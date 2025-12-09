import Foundation

@MainActor
class UserDataModel {

    static let shared = UserDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private let archiveURL: URL


    private var currentUser: User?
    var allUsers: [User] = []
    private init() {
        archiveURL =
            documentsDirectory
            .appendingPathComponent("currentUser")
            .appendingPathExtension("json")

         loadUser()
        allUsers = loadSampleUser()
    }


    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func getUser(by id: UUID) -> User? {
        return allUsers.first(where: { $0.id == id })
    }


    func saveCurrentUser(_ user: User) {
        currentUser = user
        saveUser()
    }

    func updateUser(_ updatedUser: User) {
        guard currentUser?.id == updatedUser.id else { return }
        currentUser = updatedUser
        saveUser()
    }

  
    func deleteUser(by id: UUID) {
        if currentUser?.id == id {
            currentUser = nil
            saveUser()
        }
    }

    
    func updateLastSeen() {
        guard var user = currentUser else { return }
        user.lastSeen = Date()
        saveCurrentUser(user)
    }


    func addCallRecordID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.callRecordIDs.append(id)
        saveCurrentUser(user)
    }


    func addRoleplayID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.roleplayIDs.append(id)
        saveCurrentUser(user)
    }


    func addJamSessionID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.jamSessionIDs.append(id)
        saveCurrentUser(user)
    }

  
    func addFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        user.friendsIDs.append(id)
        saveCurrentUser(user)
    }

   
    func getFriendIndex(from id: UUID) -> Int? {
        guard let user = currentUser else { return nil }
        return user.friendsIDs.firstIndex(of: id)
    }

  
    func deleteFriendID(_ id: UUID) {
        guard var user = currentUser else { return }
        guard let index = getFriendIndex(from: id) else { return }
        user.friendsIDs.remove(at: index)
        saveCurrentUser(user)
    }

  
    private func loadUser() {
        if let data = try? Data(contentsOf: archiveURL) {
            let decoder = JSONDecoder()
            currentUser = try? decoder.decode(User.self, from: data)
        }

      
        if currentUser == nil {
            currentUser = loadSampleUser().last
            saveUser()
        }
    }

    private func saveUser() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(currentUser) {
            try? data.write(to: archiveURL)
        }
    }

 
    private func loadSampleUser() -> [User] {
        return [User(
            name: "Madhav Sharma",
            email: "madhav@opentone.com",
            password: "madhav123",
            country: Country(name: "India", code: "🇮🇳"),
            age: 20,
            gender: .male,
            bio: "Learning to communicate every day and loving the progress.",
            englishLevel: .beginner,
            currentPlan: .free,
            avatar: "pp1",
            streak: nil,
            lastSeen: nil,
            callRecordIDs: [],
            roleplayIDs: [],
            jamSessionIDs: [],
            friends: []
        ) , User(
            name: "Harshdeep Singh",
            email: "harsh@opentone.com",
            password: "harsh123",
            country: Country(name: "India", code: "🇮🇳"),
            age: 19,
            gender: .male,
            bio: "On a journey to improve my Communication Skills",
            englishLevel: .beginner,
            currentPlan: .free,
            avatar: "pp2",
            streak: nil,
            lastSeen: nil,
            callRecordIDs: [],
            roleplayIDs: [],
            jamSessionIDs: [],
            friends: []
        )]
    }
}
