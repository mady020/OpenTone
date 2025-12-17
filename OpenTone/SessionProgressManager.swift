

import Foundation

class SessionProgressManager {

    static let shared = SessionProgressManager()
    private init() {}

    enum SessionType: String {
        case oneToOne
        case twoMinJam
        case roleplay
        
        var durationInMinutes: Int {
            switch self {
            case .oneToOne:
                return 10
            case .twoMinJam:
                return 2
            case .roleplay:
                return 15
            }
        }
        var xp: Int { 15 }
    }

    //private(set) var completedSessions: Set<SessionType> = []
    private(set) var completedSessionRecords: [CompletedSession] = []


//    func markCompleted(_ type: SessionType) {
//
//        completedSessions.insert(type)
//
//        let record = CompletedSession(
//            activityName: type.rawValue,
//            durationInMinutes: type.durationInMinutes,
//            xpGained: 15,
//            date: Date()
//        )
//
//        completedSessionRecords.append(record)
//    }
    func markCompleted(_ type: SessionType) {

        print(" SESSION COMPLETED:", type.rawValue)

        let session = CompletedSession(
            activityName: type.rawValue,
            durationInMinutes: type.durationInMinutes,
            xpGained: type.xp,
            date: Date()
        )

        completedSessionRecords.append(session)

        print("TOTAL SESSIONS:", completedSessionRecords.count)
    }

    func isCompleted(_ type: SessionType) -> Bool {
        completedSessionRecords.contains {
            $0.activityName == type.rawValue
        }
    }
    func overallProgress() -> Float {
        Float(completedSessionRecords.count) / 3.0
    }
    func totalMinutesCompleted() -> Int {
        completedSessionRecords.reduce(0) {
            $0 + $1.durationInMinutes
        }
    }

}
