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
    
    
    
    
    var scenarios: [RoleplayScenario] = [

        // MARK: - Grocery Shopping (FULL SCRIPT)
        RoleplayScenario(
            title: "Grocery Shopping",
            description: "Practice asking for items, prices, and payment at a grocery store.",
            imageURL: "GroceryShopping",
            category: .groceryShopping,
            difficulty: .intermediate,
            estimatedTimeMinutes: 5,
            script: [

                RoleplayMessage(
                    speaker: .npc,
                    text: "Where can I find the milk?",
                    replyOptions: [
                        "I am looking for milk, could you point me to the right section?",
                        "How much does a bottle of milk cost here?",
                        "Can you help me locate dairy products?",
                        "Is the milk fresh today?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "The milk is in the dairy section next to the eggs.",
                    replyOptions: [
                        "Great, thanks!",
                        "Can you show me directions on a map?",
                        "Do you have plant-based milk as well?",
                        "Can I pay by card at checkout?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "If you need plant-based milk, it's right beside the regular milk.",
                    replyOptions: [
                        "Amazing! I’ll check that out.",
                        "Do you have any offers on almond or oat milk?",
                        "Which one is best for coffee?",
                        "I want lactose-free milk, do you have that?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "Yes, we have lactose-free milk on the top shelf.",
                    replyOptions: [
                        "Thank you! I’ll grab one.",
                        "How long does it stay fresh?",
                        "Is it more expensive than regular milk?",
                        "Are there smaller packs available?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "You can check the price on the shelf label.",
                    replyOptions: [
                        "Perfect, I’ll take a look.",
                        "Do you have a loyalty program?",
                        "Where can I get a shopping basket?",
                        "What time does the store close?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "Baskets are available near the entrance, and yes, we close at 10 PM.",
                    replyOptions: [
                        "Thanks for the info!",
                        "Where do I find the checkout counters?",
                        "Can I self-scan the products?",
                        "Do you have a bakery section as well?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "Checkout counters are straight ahead, and the bakery is on your left.",
                    replyOptions: [
                        "I’ll grab some bread too!",
                        "Is there someone at the bakery to assist with slicing?",
                        "Do you have gluten-free bread?",
                        "Are there fresh cakes available?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "Yes, fresh cakes arrive every morning, and the staff can assist you at the bakery.",
                    replyOptions: [
                        "Nice! I’ll check them out.",
                        "Do you have any seasonal items?",
                        "Where can I find snacks or chips?",
                        "Is there a section for cold drinks?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "Snacks are in aisle 5 and cold drinks are near the checkout refrigerators.",
                    replyOptions: [
                        "Wonderful, thank you so much!",
                        "Do you also have a pharmacy section?",
                        "Where are the cleaning supplies?",
                        "Can I ask for home delivery?"
                    ]
                ),

                RoleplayMessage(
                    speaker: .npc,
                    text: "We do provide home delivery—please ask at the service desk near the entrance.",
                    replyOptions: [
                        "Thanks! That’s very helpful.",
                        "I’ll sign up for delivery later.",
                        "Can I get assistance loading groceries into my car?",
                        "Do you sell gift cards?"
                    ]
                )
            ]
        ),

        // MARK: - Making Friends
        RoleplayScenario(
            title: "Making Friends",
            description: "Learn how to start and continue a friendly conversation.",
            imageURL: "MakingFriends",
            category: .custom,
            difficulty: .intermediate,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(
                    speaker: .npc,
                    text: "Hi, I haven't seen you here before.",
                    replyOptions: [
                        "Hi! I'm new here.",
                        "Hello! Nice to meet you.",
                        "Yeah, I just joined recently.",
                        "Hey! How are you?"
                    ]
                ),
                RoleplayMessage(
                    speaker: .npc,
                    text: "What course are you studying?",
                    replyOptions: [
                        "I'm studying computer science.",
                        "Business management.",
                        "Engineering.",
                        "Still deciding!"
                    ]
                )
            ]
        ),

        // MARK: - Airport Check-in
        RoleplayScenario(
            title: "Airport Check-in",
            description: "Practice check-in conversation at an airport counter.",
            imageURL: "AirportCheck-in",
            category: .travel,
            difficulty: .advanced,
            estimatedTimeMinutes: 6,
            script: [
                RoleplayMessage(
                    speaker: .npc,
                    text: "May I see your passport and ticket?",
                    replyOptions: [
                        "Sure, here you go.",
                        "Yes, one moment please.",
                        "Here are my documents.",
                        "I have them on my phone."
                    ]
                ),
                RoleplayMessage(
                    speaker: .npc,
                    text: "Do you have any luggage to check in?",
                    replyOptions: [
                        "Yes, one suitcase.",
                        "No, just carry-on.",
                        "Two bags, please.",
                        "Only a backpack."
                    ]
                )
            ]
        ),

        // MARK: - Ordering Food
        RoleplayScenario(
            title: "Ordering Food",
            description: "Practice ordering food at a restaurant.",
            imageURL: "OrderingFood",
            category: .restaurant,
            difficulty: .beginner,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(
                    speaker: .npc,
                    text: "Welcome! May I take your order?",
                    replyOptions: [
                        "Yes, I’d like to see the menu.",
                        "Can you recommend something?",
                        "I’m ready to order.",
                        "Just water for now."
                    ]
                )
            ]
        ),

        // MARK: - Job Interview
        RoleplayScenario(
            title: "Job Interview",
            description: "Practice answering common interview questions.",
            imageURL: "JobInterview",
            category: .interview,
            difficulty: .advanced,
            estimatedTimeMinutes: 8,
            script: [
                RoleplayMessage(
                    speaker: .npc,
                    text: "Tell me about yourself.",
                    replyOptions: [
                        "I'm a motivated and hardworking individual.",
                        "I recently graduated and love learning.",
                        "I have experience in this field.",
                        "I'm passionate about this role."
                    ]
                )
            ]
        ),

        // MARK: - Hotel Booking
        RoleplayScenario(
            title: "Hotel Booking",
            description: "Practice booking a hotel room at the reception.",
            imageURL: "HotelBooking",
            category: .restaurant,
            difficulty: .intermediate,
            estimatedTimeMinutes: 6,
            script: [
                RoleplayMessage(
                    speaker: .npc,
                    text: "How many nights will you be staying?",
                    replyOptions: [
                        "Two nights.",
                        "Just one night.",
                        "Three nights.",
                        "I’m not sure yet."
                    ]
                )
            ]
        )
    ]


}
