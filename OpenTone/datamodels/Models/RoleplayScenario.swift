import Foundation

struct RoleplayScenario: Identifiable, Codable, Equatable {

    let id: UUID
    let title: String
    let description: String

    /// Local asset name or remote URL depending on usage.
    let imageURL: String

    let category: RoleplayCategory
    let difficulty: RoleplayDifficulty
    let estimatedTimeMinutes: Int

    /// Full dialogue script (alternating speaker lines).
    let script: [RoleplayMessage]

    // MARK: - Computed Helpers

    /// Lines shown on detail screen before starting.
    var previewLines: [RoleplayMessage] {
        Array(script.prefix(2))
    }

    // MARK: - Init

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