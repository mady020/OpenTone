import Foundation

@MainActor
class RoleplayScenarioDataModel {

    static let shared = RoleplayScenarioDataModel()

    private init() {}

    
    var scenarios: [RoleplayScenario] = [

        RoleplayScenario(
            title: "Grocery Shopping",
            description: "Practice asking questions and finding items in a grocery store.",
            imageURL: "GroceryShopping",
            category: .groceryShopping,
            difficulty: .beginner,
            estimatedTimeMinutes: 3,
            script: [
                RoleplayMessage(sender: .app, text: "Where can I find the milk?"),
                RoleplayMessage(sender: .user, text: "I am looking for milk, could you help?")
            ]
        ),

        RoleplayScenario(
            title: "Making Friends",
            description: "Learn how to start friendly conversations and introduce yourself.",
            imageURL: "MakingFriends",
            category: .custom,
            difficulty: .beginner,
            estimatedTimeMinutes: 3,
            script: [
                RoleplayMessage(sender: .app, text: "Hi! What's your name?"),
                RoleplayMessage(sender: .user, text: "My name is...")
            ]
        ),

        RoleplayScenario(
            title: "Airport Check-in",
            description: "Practice checking in at an airport counter smoothly.",
            imageURL: "AirportCheck-in",
            category: .travel,
            difficulty: .beginner,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(sender: .app, text: "May I see your passport?"),
                RoleplayMessage(sender: .user, text: "Sure, here it is.")
            ]
        ),

        RoleplayScenario(
            title: "Ordering Food",
            description: "Learn how to place an order politely and clearly at a restaurant.",
            imageURL: "OrderingFood",
            category: .restaurant,
            difficulty: .intermediate,
            estimatedTimeMinutes: 3,
            script: [
                RoleplayMessage(sender: .app, text: "What would you like to order today?"),
                RoleplayMessage(sender: .user, text: "I'd like a burger and fries.")
            ]
        ),

        RoleplayScenario(
            title: "Job Interview",
            description: "Practice answering common job interview questions confidently.",
            imageURL: "JobInterview",
            category: .interview,
            difficulty: .advanced,
            estimatedTimeMinutes: 5,
            script: [
                RoleplayMessage(sender: .app, text: "Tell me about yourself."),
                RoleplayMessage(sender: .user, text: "I am...")
            ]
        ),

        RoleplayScenario(
            title: "Birthday Celebration",
            description: "Learn how to talk and interact during a birthday event.",
            imageURL: "BirthdayCelebration",
            category: .custom,
            difficulty: .intermediate,
            estimatedTimeMinutes: 2,
            script: [
                RoleplayMessage(sender: .app, text: "Would you like some cake?"),
                RoleplayMessage(sender: .user, text: "Yes please!")
            ]
        ),

        RoleplayScenario(
            title: "Hotel Booking",
            description: "Practice speaking to a hotel receptionist for booking a room.",
            imageURL: "HotelBooking",
            category: .travel,
            difficulty: .intermediate,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(sender: .app, text: "Do you have a reservation?"),
                RoleplayMessage(sender: .user, text: "No, I'd like to book a room.")
            ]
        )
        
        
        
    ]



    // private let scenariosURL = URL(string: "https://your-api.com/scenarios")!

//    func fetchScenarios() {
//        self.scenarios = []
//    }


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



