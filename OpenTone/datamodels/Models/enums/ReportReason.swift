import Foundation

enum ReportReason: String, Codable, Sendable {
    case inappropriateBehavior = "Inappropriate Behavior"
    case abusiveLanguage = "Abusive Language"
    case spam = "Spam / Advertising"
    case harassment = "Harassment / Bullying"
    case fakeProfile = "Fake / Impersonation"
    case other = "Other"
}

