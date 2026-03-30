import Foundation




@MainActor
class RoleplayScenarioDataModel {

    static let shared = RoleplayScenarioDataModel()

    private init() {}


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
    
    func getRecommended(for interests: Set<InterestItem>?) -> [RoleplayScenario] {
        guard let interests = interests, !interests.isEmpty else {
            return Array(scenarios.prefix(5))
        }
        
        let interestTitles = Set(interests.map { $0.title })
        
        let scoredScenarios = scenarios.compactMap { scenario -> (RoleplayScenario, Int)? in
            let overlapCount = scenario.relatedInterests.filter { interestTitles.contains($0) }.count
            return overlapCount > 0 ? (scenario, overlapCount) : nil
        }
        
        let recommended = scoredScenarios
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        
        if !recommended.isEmpty {
            return Array(recommended.prefix(5))
        } else {
            return Array(scenarios.prefix(5))
        }
    }
}
