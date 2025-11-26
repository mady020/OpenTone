

import Foundation

class SessionProgressManager {

    static let shared = SessionProgressManager()

    private init() {}

    enum SessionType: String {
        case oneToOne
        case twoMinJam
        case roleplay
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
}
