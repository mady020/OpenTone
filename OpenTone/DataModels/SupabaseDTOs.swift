//
//  SupabaseDTOs.swift
//  OpenTone
//
//  Supabase row types — these map 1:1 to Postgres table columns.
//  Used by DataModel managers for insert / select / update operations.
//

import Foundation

// MARK: - User Row

struct UserRow: Codable {
    let id: UUID
    var name: String
    var email: String
    var countryName: String?
    var countryCode: String?
    var avatar: String?
    var age: Int?
    var gender: String?
    var bio: String?
    var goal: Int
    var englishLevel: String?
    var confidenceTitle: String?
    var confidenceEmoji: String?
    var interests: [InterestItem]?
    var currentPlan: String?
    var streakCommitment: Int?
    var streakCurrent: Int?
    var streakLongest: Int?
    var streakLastActive: Date?
    var lastSeen: Date?
    var friendIds: [UUID]?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email, avatar, age, gender, bio, goal, interests
        case countryName    = "country_name"
        case countryCode    = "country_code"
        case englishLevel   = "english_level"
        case confidenceTitle = "confidence_title"
        case confidenceEmoji = "confidence_emoji"
        case currentPlan    = "current_plan"
        case streakCommitment = "streak_commitment"
        case streakCurrent  = "streak_current"
        case streakLongest  = "streak_longest"
        case streakLastActive = "streak_last_active"
        case lastSeen       = "last_seen"
        case friendIds      = "friend_ids"
        case createdAt      = "created_at"
    }
}

// MARK: - User ↔ UserRow Conversion

extension UserRow {
    /// Convert a domain `User` into a Supabase row.
    init(from user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.countryName = user.country?.name
        self.countryCode = user.country?.code
        self.avatar = user.avatar
        self.age = user.age
        self.gender = user.gender?.rawValue
        self.bio = user.bio
        self.goal = user.goal
        self.englishLevel = user.englishLevel?.rawValue
        self.confidenceTitle = user.confidenceLevel?.title
        self.confidenceEmoji = user.confidenceLevel?.emoji
        self.interests = user.interests.map { Array($0) }
        self.currentPlan = user.currentPlan?.rawValue
        self.streakCommitment = user.streak?.commitment
        self.streakCurrent = user.streak?.currentCount
        self.streakLongest = user.streak?.longestCount
        self.streakLastActive = user.streak?.lastActiveDate
        self.lastSeen = user.lastSeen
        self.friendIds = user.friendsIDs
        self.createdAt = nil // server-generated
    }

    /// Convert a Supabase row back to a domain `User`.
    func toUser() -> User {
        var user = User(
            name: name,
            email: email,
            password: "",
            country: countryCode != nil ? Country(name: countryName ?? "", code: countryCode!) : nil,
            age: age,
            gender: gender.flatMap { Gender(rawValue: $0) },
            bio: bio,
            englishLevel: englishLevel.flatMap { EnglishLevel(rawValue: $0) },
            confidenceLevel: (confidenceTitle != nil && confidenceEmoji != nil)
                ? ConfidenceOption(title: confidenceTitle!, emoji: confidenceEmoji!)
                : nil,
            interests: interests.map { Set($0) },
            currentPlan: currentPlan.flatMap { UserPlan(rawValue: $0) },
            avatar: avatar,
            streak: Streak(
                commitment: streakCommitment ?? 0,
                currentCount: streakCurrent ?? 0,
                longestCount: streakLongest ?? 0,
                lastActiveDate: streakLastActive
            ),
            lastSeen: lastSeen,
            roleplayIDs: [],     // not stored in users table; counts derived from activities
            jamSessionIDs: [],   // not stored in users table; counts derived from activities
            friends: friendIds ?? [],
            createdAt: createdAt,
            goal: goal
        )
        // Override the auto-generated UUID with the one from the database
        user.setID(id)
        return user
    }
}

// MARK: - Activity Row

struct ActivityRow: Codable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let date: Date
    let topic: String
    let duration: Int
    let imageUrl: String?
    let xpEarned: Int
    let isCompleted: Bool
    let scenarioId: UUID?
    let roleplaySession: RoleplaySession?
    let feedback: SessionFeedback?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, title, date, topic, duration, feedback
        case userId         = "user_id"
        case imageUrl       = "image_url"
        case xpEarned       = "xp_earned"
        case isCompleted    = "is_completed"
        case scenarioId     = "scenario_id"
        case roleplaySession = "roleplay_session"
        case createdAt      = "created_at"
    }

    init(from activity: Activity, userId: UUID) {
        self.id = activity.id
        self.userId = userId
        self.type = activity.type.rawValue
        self.title = activity.title
        self.date = activity.date
        self.topic = activity.topic
        self.duration = activity.duration
        self.imageUrl = activity.imageURL
        self.xpEarned = activity.xpEarned
        self.isCompleted = activity.isCompleted
        self.scenarioId = activity.scenarioId
        self.roleplaySession = activity.roleplaySession
        self.feedback = activity.feedback
        self.createdAt = nil // server-generated
    }

    func toActivity() -> Activity {
        var activity = Activity(
            type: ActivityType(rawValue: type) ?? .aiCall,
            date: date,
            topic: topic,
            duration: duration,
            xpEarned: xpEarned,
            isCompleted: isCompleted,
            title: title,
            imageURL: imageUrl ?? "",
            roleplaySession: roleplaySession,
            feedback: feedback,
            scenarioId: scenarioId
        )
        activity.setID(id)
        return activity
    }
}



// MARK: - JamSession Row

struct JamSessionRow: Codable {
    let id: UUID
    let userId: UUID
    var topic: String
    var suggestions: [String]
    var phase: String
    var secondsLeft: Int
    var startedPrepAt: Date?
    var startedSpeakingAt: Date?
    var endedAt: Date?
    var isSaved: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, topic, suggestions, phase
        case userId          = "user_id"
        case secondsLeft     = "seconds_left"
        case startedPrepAt   = "started_prep_at"
        case startedSpeakingAt = "started_speaking_at"
        case endedAt         = "ended_at"
        case isSaved         = "is_saved"
        case createdAt       = "created_at"
    }

    init(from session: JamSession, isSaved: Bool = false) {
        self.id = session.id
        self.userId = session.userId
        self.topic = session.topic
        self.suggestions = session.suggestions
        self.phase = session.phase.rawValue
        self.secondsLeft = session.secondsLeft
        self.startedPrepAt = session.startedPrepAt
        self.startedSpeakingAt = session.startedSpeakingAt
        self.endedAt = session.endedAt
        self.isSaved = isSaved
        self.createdAt = nil // server-generated
    }

    func toJamSession() -> JamSession {
        var session = JamSession(
            userId: userId,
            topic: topic,
            suggestions: suggestions,
            phase: JamPhase(rawValue: phase) ?? .preparing,
            secondsLeft: secondsLeft
        )
        session.setID(id)
        session.startedPrepAt = startedPrepAt
        session.startedSpeakingAt = startedSpeakingAt
        session.endedAt = endedAt
        return session
    }
}

// MARK: - CompletedSession Row

struct CompletedSessionRow: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let title: String
    let subtitle: String
    let topic: String
    let durationMinutes: Int
    let xp: Int
    let iconName: String

    enum CodingKeys: String, CodingKey {
        case id, date, title, subtitle, topic, xp
        case userId          = "user_id"
        case durationMinutes = "duration_minutes"
        case iconName        = "icon_name"
    }

    init(from session: CompletedSession, userId: UUID) {
        self.id = session.id
        self.userId = userId
        self.date = session.date
        self.title = session.title
        self.subtitle = session.subtitle
        self.topic = session.topic
        self.durationMinutes = session.durationMinutes
        self.xp = session.xp
        self.iconName = session.iconName
    }

    func toCompletedSession() -> CompletedSession {
        CompletedSession(
            id: id,
            date: date,
            title: title,
            subtitle: subtitle,
            topic: topic,
            durationMinutes: durationMinutes,
            xp: xp,
            iconName: iconName
        )
    }
}

// MARK: - RoleplaySession Row

struct RoleplaySessionRow: Codable {
    let id: UUID
    let userId: UUID
    let scenarioId: UUID
    var currentLineIndex: Int
    var messages: [RoleplayMessage]
    var status: String
    let startedAt: Date
    var endedAt: Date?
    var feedback: SessionFeedback?
    var xpEarned: Int
    var isSaved: Bool

    enum CodingKeys: String, CodingKey {
        case id, messages, status, feedback
        case userId          = "user_id"
        case scenarioId      = "scenario_id"
        case currentLineIndex = "current_line_index"
        case startedAt       = "started_at"
        case endedAt         = "ended_at"
        case xpEarned        = "xp_earned"
        case isSaved         = "is_saved"
    }

    init(from session: RoleplaySession, isSaved: Bool = false) {
        self.id = session.id
        self.userId = session.userId
        self.scenarioId = session.scenarioId
        self.currentLineIndex = session.currentLineIndex
        self.messages = session.messages
        self.status = session.status.rawValue
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.feedback = session.feedback
        self.xpEarned = session.xpEarned
        self.isSaved = isSaved
    }

    func toRoleplaySession() -> RoleplaySession {
        var session = RoleplaySession(
            userId: userId,
            scenarioId: scenarioId,
            status: RoleplayStatus(rawValue: status) ?? .notStarted,
            startedAt: startedAt,
            xpEarned: xpEarned
        )
        session.setID(id)
        session.currentLineIndex = currentLineIndex
        session.messages = messages
        session.endedAt = endedAt
        session.feedback = feedback
        return session
    }
}

// MARK: - CallRecord Row

struct CallRecordRow: Codable {
    let id: UUID
    let userId: UUID
    let participantId: UUID
    var participantName: String?
    var participantAvatarUrl: String?
    var participantBio: String?
    var participantInterests: [String]?
    let callDate: Date
    var duration: Double
    var userStatus: String

    enum CodingKeys: String, CodingKey {
        case id, duration
        case userId              = "user_id"
        case participantId       = "participant_id"
        case participantName     = "participant_name"
        case participantAvatarUrl = "participant_avatar_url"
        case participantBio      = "participant_bio"
        case participantInterests = "participant_interests"
        case callDate            = "call_date"
        case userStatus          = "user_status"
    }

    init(from record: CallRecord) {
        self.id = record.id
        self.userId = record.userId
        self.participantId = record.participantId
        self.participantName = record.participantName
        self.participantAvatarUrl = record.participantAvatarUrl
        self.participantBio = record.participantBio
        self.participantInterests = record.participantInterests
        self.callDate = record.callDate
        self.duration = record.duration
        self.userStatus = record.userStatus.rawValue
    }

    func toCallRecord() -> CallRecord {
        var record = CallRecord(
            userId: userId,
            participantId: participantId,
            participantName: participantName,
            participantAvatarUrl: participantAvatarUrl,
            participantBio: participantBio,
            participantInterests: participantInterests,
            callDate: callDate,
            duration: duration,
            userStatus: UserStatus(rawValue: userStatus) ?? .offline
        )
        record.setID(id)
        return record
    }
}

// MARK: - Report Row

struct ReportRow: Codable {
    let id: String
    let reporterUserId: String
    let reportedEntityId: String
    let entityType: String
    let reason: String
    let reasonDetails: String?
    let message: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, reason, message, timestamp
        case reporterUserId   = "reporter_user_id"
        case reportedEntityId = "reported_entity_id"
        case entityType       = "entity_type"
        case reasonDetails    = "reason_details"
    }

    init(from report: Report) {
        self.id = report.id
        self.reporterUserId = report.reporterUserID
        self.reportedEntityId = report.reportedEntityID
        self.entityType = report.entityType.rawValue
        self.reason = report.reason.rawValue
        self.reasonDetails = report.reasonDetails
        self.message = report.message
        self.timestamp = report.timestamp
    }

    func toReport() -> Report {
        Report(
            id: id,
            reporterUserID: reporterUserId,
            reportedEntityID: reportedEntityId,
            entityType: ReportedEntityType(rawValue: entityType) ?? .user,
            reason: ReportReason(rawValue: reason) ?? .other,
            reasonDetails: reasonDetails,
            message: message,
            timestamp: timestamp
        )
    }
}
