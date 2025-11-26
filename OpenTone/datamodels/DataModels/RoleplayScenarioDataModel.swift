import Foundation

@MainActor
class RoleplayScenarioDataModel {

    static let shared = RoleplayScenarioDataModel()

    private init() {}

    private(set) var scenarios: [RoleplayScenario] = []

    // private let scenariosURL = URL(string: "https://your-api.com/scenarios")!

    func fetchScenarios() {
        self.scenarios = []
    }


    func getAll() -> [RoleplayScenario] {
        return scenarios
    }


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
