import Foundation

enum OnboardingDestination {
    case login
    case userInfo
    case confidence
    case interestsIntro
    case commitment
    case dashboard
}

enum OnboardingDestinationResolver {

    static func destination(for user: User?) -> OnboardingDestination {
        guard let user else {
            return .login
        }

        let hasBio = !(user.bio?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if !hasBio || user.country == nil {
            return .userInfo
        }

        if user.confidenceLevel == nil {
            return .confidence
        }

        let interestsCount = user.interests?.count ?? 0
        if interestsCount < 3 {
            return .interestsIntro
        }

        if user.streak == nil {
            return .commitment
        }

        return .dashboard
    }
}
