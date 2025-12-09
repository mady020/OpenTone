import Foundation



struct User: Identifiable, Codable, CustomStringConvertible{
    
    let id: UUID
    var name: String
    var email: String
    var password: String
    var country: Country?
    var avatar: String?
    var age: Int?
    var gender: Gender?
    var bio: String?
    var goal: Int
    var englishLevel: EnglishLevel?
    var confidenceLevel: ConfidenceOption?
    var interests: Set<InterestItem>?
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
        password: String,
        country: Country?,
        age: Int? = nil,
        gender: Gender? = nil,
        bio: String? = nil,
        englishLevel: EnglishLevel? = nil,
        interests: Set<InterestItem>? = nil,
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
        self.password = password
        self.country = country
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
    
    var isOnline: Bool {
        guard let last = lastSeen else { return false }
        return Date().timeIntervalSince(last) < 60
    }
    var description: String {
        var parts: [String] = []
        parts.append("id: \(id)")
        parts.append("name: \(name)")
        parts.append("email: \(email)")
        parts.append("country: \(country?.name ?? "N/A")")
        parts.append("age: \(age?.description ?? "N/A")")
        parts.append("gender: \(gender?.rawValue ?? "N/A")")
        parts.append("bio: \(bio ?? "N/A")")
        parts.append("goal: \(goal)")
        parts.append("english level: \(englishLevel?.rawValue ?? "N/A")")
     
        parts.append("interests count: \(interests?.count ?? 0)")
     
        parts.append("avatar: \(avatar ?? "N/A")")
        parts.append("streak: \(streak?.commitment.description ?? "N/A")")
        parts.append("last seen: \(lastSeen?.description ?? "N/A")")
        parts.append("call records: \(callRecordIDs.count)")
        parts.append("roleplays: \(roleplayIDs.count)")
        parts.append("jam sessions: \(jamSessionIDs.count)")
        parts.append("friends: \(friendsIDs.count)")
        return parts.joined(separator: "\n")
    }

}
