import Foundation

struct User: Identifiable, Codable, Equatable {

    let id: UUID
    var name: String
    var email: String
    var avatar: String?
    var age: Int?
    var gender: Gender?
    var bio: String?
    var goal: Int
    var englishLevel: EnglishLevel?
    var interests: [Interest]?
    var currentPlan: UserPlan?
    var streak: Streak?
    var lastSeen: Date?
    var callRecordIDs: [UUID]
    var roleplayIDs: [UUID]
    var jamSessionIDs: [UUID]
    var friendsIDs: [UUID]

    init(
        name: String,
        email: String,
        age: Int? = nil,
        gender: Gender? = nil,
        bio: String? = nil,
        englishLevel: EnglishLevel? = nil,
        interests: [Interest]? = nil,
        currentPlan: UserPlan? = nil,
        avatar: String? = nil,
        streak: Streak? = nil,
        lastSeen: Date? = nil,
        callRecordIDs: [UUID] = [],
        roleplayIDs: [UUID] = [],
        jamSessionIDs: [UUID] = [],
        friends: [UUID] = [],
        goal: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.bio = bio
        self.englishLevel = englishLevel
        self.interests = interests
        self.currentPlan = currentPlan
        self.avatar = avatar
        self.streak = streak
        self.lastSeen = lastSeen
        self.callRecordIDs = callRecordIDs
        self.roleplayIDs = roleplayIDs
        self.jamSessionIDs = jamSessionIDs
        self.friendsIDs = friends
        self.goal = goal
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }

     var isOnline: Bool {
        guard let last = lastSeen else { return false }
        return Date().timeIntervalSince(last) < 60
    }
}