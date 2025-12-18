
import Foundation

struct CompletedSession: Codable {
    let id: UUID
    let date: Date
    let title: String
    let subtitle: String
    let topic: String
    let durationMinutes: Int
    let xp: Int
    let iconName: String
}
