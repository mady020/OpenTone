import Foundation

@MainActor
class CallSessionDataModel {

    static let shared = CallSessionDataModel()

    private init() {}

    private(set) var activeSession: CallSession?


    func startSession(_ session: CallSession) {
        activeSession = session
    }

    func endSession() {
        guard let session = activeSession else { return }
        var finished = session
        finished.endedAt = Date()


        if let start = session.startedAt as Date?,
           let end = finished.endedAt {

            let duration = Int(end.timeIntervalSince(start))

            HistoryDataModel.shared.logActivity(
                type: .call,
                title: "Call Session",
                topic: "Conversation",
                duration: duration,
                imageURL: "call_icon",
                xpEarned: 8,
                isCompleted: true
            )
        }

        activeSession = nil
    }

    func getActiveSession() -> CallSession? {
        return activeSession
    }


    
    func getMatches(interests: [Interest], gender: Gender, englishLevel: EnglishLevel) -> [UUID]? {

        guard UserDataModel.shared.getCurrentUser() != nil else { return nil }

    
        let allUsers = UserDataModel.shared.allUsers

//        let filtered = allUsers.filter { user in
//
//            guard user.id != currentUser.id else { return false }
//
//    
//            let common = user.interests?.intersection(interests)
//
//            return !common.isEmpty
//                && (gender == .any || user.gender == gender)
//                && user.englishLevel == englishLevel
//        }

//        return filtered.map { $0.id }
        
        return [allUsers.first?.id ?? UUID()]
    }




    func getParticipantDetails(from user: User) -> (
        name: String,
        bio: String?,
        image: String?,
        sharedInterests: Set<InterestItem>?
    ) {

        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            return (user.name, user.bio, user.avatar, user.interests)
        }

        let shared = Set(currentUser.interests ?? [])
            .intersection(Set(user.interests ?? []))

        return (
            name: user.name,
            bio: user.bio,
            image: user.avatar,
            sharedInterests: shared
        )
    }


    func generateSuggestedQuestions(from interests: [Interest]?) -> [String] {

        guard let interests: [Interest] = interests, !interests.isEmpty else {
            return [
                "What did you do today?",
                "What are your hobbies?",
                "What's something you want to improve?",
            ]
        }

        var questions: [String] = []

        for interest: Interest in interests {

            switch interest.rawValue.lowercased() {

            case "music":
                questions += [
                    "What kind of music do you enjoy?",
                    "Do you play any instruments?"
                ]

            case "sports":
                questions += [
                    "Which sport do you follow?",
                    "Do you support any teams?"
                ]

            case "coding":
                questions += [
                    "What language do you enjoy coding in?",
                    "What project are you working on?"
                ]

            case "travel":
                questions += [
                    "What was your favourite trip?",
                    "Where do you want to go next?"
                ]

            case "reading":
                questions += [
                    "What book impacted you the most?",
                    "What genres do you like reading?"
                ]

            default:
                questions += [
                    "How did you get into \(interest.rawValue)?",
                    "What do you enjoy about \(interest.rawValue)?"
                ]
            }
        }

        return Array(questions.prefix(5))

    }
}
