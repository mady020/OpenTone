import Foundation

@MainActor
class RoleplayScenarioDataModel {

    static let shared = RoleplayScenarioDataModel()

    private init() {}

    private(set) var scenarios: [RoleplayScenario] = []

    // private let scenariosURL = URL(string: "https://your-api.com/scenarios")!

    /// Fetches roleplay scenarios from your backend API.
    /// Stores them in memory and optionally caches them.
    func fetchScenarios() {
        self.scenarios = []
    }

    /// Returns all scenarios.
    func getAll() -> [RoleplayScenario] {
        return scenarios
    }

    /// Filter scenarios based on difficuly and category
    func filter(
        category: RoleplayCategory? = nil,
        difficulty: RoleplayDifficulty? = nil
    ) -> [RoleplayScenario] {

        scenarios.filter { scenario in
            let matchesCategory = category == nil || scenario.category == category!
            let matchesDifficulty = difficulty == nil || scenario.difficulty == difficulty!
            return matchesCategory && matchesDifficulty
        }
    }

    func getScenario(by id: UUID) -> RoleplayScenario? {
        scenarios.first { $0.id == id }
    }
}
