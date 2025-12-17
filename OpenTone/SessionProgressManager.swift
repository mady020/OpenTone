

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
    }

    private(set) var completedSessions: Set<SessionType> = []

    func markCompleted(_ type: SessionType) {
        completedSessions.insert(type)
    }

    func isCompleted(_ type: SessionType) -> Bool {
        return completedSessions.contains(type)
    }

    func overallProgress() -> Float {
        return Float(completedSessions.count) / 3.0
    }
    func totalMinutesCompleted() -> Int {
        return completedSessions.reduce(into: 0) {
            $0 + $1.durationInMinutes
        }
    }

}
