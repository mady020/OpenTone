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
                RoleplayMessage(sender: .app, text: "Where can I find the milk?", suggestedMessages: [
                    "I am looking for milk, could you point me to the right section?",
                    "How much does a bottle of milk cost here?",
                    "Can you help me locate dairy products?",
                    "Is the milk fresh today?"
                ]),
                RoleplayMessage(sender: .user, text: "The milk is in the dairy section next to the eggs.", suggestedMessages: [
                    "Great, thanks!",
                    "Can you show me directions on a map?",
                    "Do you have plant-based milk as well?",
                    "Can I pay by card at checkout?"
                ]),
                RoleplayMessage(sender: .user, text: "If you need plant-based milk, it's right beside the regular milk.", suggestedMessages: [
                    "Amazing! I’ll check that out.",
                    "Do you have any offers on almond or oat milk?",
                    "Which one is best for coffee?",
                    "I want lactose-free milk, do you have that?"
                ]),
                RoleplayMessage(sender: .user, text: "Yes, we have lactose-free milk on the top shelf.", suggestedMessages: [
                    "Thank you! I’ll grab one.",
                    "How long does it stay fresh?",
                    "Is it more expensive than regular milk?",
                    "Are there smaller packs available?"
                ]),
                RoleplayMessage(sender: .user, text: "You can check the price on the shelf label.", suggestedMessages: [
                    "Perfect, I’ll take a look.",
                    "Do you have a loyalty program?",
                    "Where can I get a shopping basket?",
                    "What time does the store close?"
                ]),
                RoleplayMessage(sender: .user, text: "Baskets are available near the entrance, and yes, we close at 10 PM.", suggestedMessages: [
                    "Thanks for the info!",
                    "Where do I find the checkout counters?",
                    "Can I self-scan the products?",
                    "Do you have a bakery section as well?"
                ]),
                RoleplayMessage(sender: .user, text: "Checkout counters are straight ahead, and the bakery is on your left.", suggestedMessages: [
                    "I’ll grab some bread too!",
                    "Is there someone at the bakery to assist with slicing?",
                    "Do you have gluten-free bread?",
                    "Are there fresh cakes available?"
                ]),
                RoleplayMessage(sender: .user, text: "Yes, fresh cakes arrive every morning, and the staff can assist you at the bakery.", suggestedMessages: [
                    "Nice! I’ll check them out.",
                    "Do you have any seasonal items?",
                    "Where can I find snacks or chips?",
                    "Is there a section for cold drinks?"
                ]),
                RoleplayMessage(sender: .user, text: "Snacks are in aisle 5 and cold drinks are near the checkout refrigerators.", suggestedMessages: [
                    "Wonderful, thank you so much!",
                    "Do you also have a pharmacy section?",
                    "Where are the cleaning supplies?",
                    "Can I ask for home delivery?"
                ]),
                RoleplayMessage(sender: .user, text: "We do provide home delivery—please ask at the service desk near the entrance.", suggestedMessages: [
                    "Thanks! That’s very helpful.",
                    "I’ll sign up for delivery later.",
                    "Can I get assistance loading groceries into my car?",
                    "Do you sell gift cards?"
                ]),
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
//                RoleplayMessage(sender: .app, text: "Hi! What's your name?"),
//                RoleplayMessage(sender: .user, text: "My name is...")
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
//                RoleplayMessage(sender: .app, text: "May I see your passport?"),
//                RoleplayMessage(sender: .user, text: "Sure, here it is.")
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
//                RoleplayMessage(sender: .app, text: "What would you like to order today?"),
//                RoleplayMessage(sender: .user, text: "I'd like a burger and fries.")
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
//                RoleplayMessage(sender: .app, text: "Tell me about yourself."),
//                RoleplayMessage(sender: .user, text: "I am...")
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
//                RoleplayMessage(sender: .app, text: "Would you like some cake?"),
//                RoleplayMessage(sender: .user, text: "Yes please!")
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
//                RoleplayMessage(sender: .app, text: "Do you have a reservation?"),
//                RoleplayMessage(sender: .user, text: "No, I'd like to book a room.")
            ]
        )
        
        
        
    ]
    

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



