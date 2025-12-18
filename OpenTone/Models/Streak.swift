import Foundation

struct Streak: Codable {
    var commitment: Int
    var currentCount: Int
    var longestCount: Int
    var lastActiveDate: Date?
}
