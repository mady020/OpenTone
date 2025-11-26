import Foundation

struct CallSession: Identifiable, Codable {
    let id: UUID
    let participantOneID: UUID
    var participantTwoID: UUID?
    var interests: [Interest]
    var gender: Gender
    var englishLevel: EnglishLevel
    var isConnected: Bool
    let startedAt: Date
    var endedAt: Date?

    init(
        participantOneID: UUID,
        interests: [Interest],
        gender: Gender,
        englishLevel: EnglishLevel,
        startedAt: Date = Date()
    ) {
        self.id = UUID()
        self.participantOneID = participantOneID
        self.participantTwoID = nil 
        self.interests = interests
        self.gender = gender
        self.englishLevel = englishLevel
        self.isConnected = false
        self.startedAt = startedAt
        self.endedAt = nil
    }
}
