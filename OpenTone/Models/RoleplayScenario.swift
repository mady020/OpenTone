import Foundation

struct RoleplayScenario: Identifiable, Codable, Equatable {

    let id: UUID
    let title: String
    let description: String
    let imageURL: String
    let category: RoleplayCategory
    let difficulty: RoleplayDifficulty
    let estimatedTimeMinutes: Int
    let script: [RoleplayMessage]
    var previewLines: [RoleplayMessage] {
        Array(script.prefix(2))
    }
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        imageURL: String,
        category: RoleplayCategory,
        difficulty: RoleplayDifficulty,
        estimatedTimeMinutes: Int,
        script: [RoleplayMessage]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.category = category
        self.difficulty = difficulty
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.script = script
    }

    static func == (lhs: RoleplayScenario, rhs: RoleplayScenario) -> Bool {
        lhs.id == rhs.id
    }
}


