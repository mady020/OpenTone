import Foundation

struct CallRecord: Identifiable, Codable {
    let id: UUID
    let participantID: UUID
    let participantName: String?
    let participantAvatarURL: String?
    let participantBio: String?
    let participantInterests: [Interest]?
    let callDate: Date
    let duration: TimeInterval
    let userStatus: UserStatus
    init(
        participantID: UUID,
        participantName: String?,
        participantAvatarURL: String?,
        participantBio: String?,
        participantInterests: [Interest]?,
        callDate: Date,
        duration: TimeInterval,
        userStatus: UserStatus
    ) {
        self.id = UUID()
        self.participantID = participantID
        self.participantName = participantName
        self.participantAvatarURL = participantAvatarURL
        self.participantBio = participantBio
        self.participantInterests = participantInterests
        self.callDate = callDate
        self.duration = duration
        self.userStatus = userStatus
    }
}