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
            case .oneToOne: return 10
            case .twoMinJam: return 2
            case .roleplay: return 15
            }
        }

        var xp: Int {
            switch self {
            case .oneToOne: return 20
            case .twoMinJam: return 15
            case .roleplay: return 25
            }
        }

        var title: String {
            switch self {
            case .oneToOne: return "1 to 1 Call"
            case .twoMinJam: return "2 Min Session"
            case .roleplay: return "Roleplay"
            }
        }

        var iconName: String {
            switch self {
            case .oneToOne: return "phone.fill"
            case .twoMinJam: return "mic.fill"
            case .roleplay: return "theatermasks.fill"
            }
        }
    }

    func markCompleted(_ type: SessionType, topic: String) {

        StreakDataModel.shared.logSession(
            title: type.title,
            subtitle: "You completed a session",
            topic: topic,
            durationMinutes: type.durationInMinutes,
            xp: type.xp,
            iconName: type.iconName
        )
    }
}
