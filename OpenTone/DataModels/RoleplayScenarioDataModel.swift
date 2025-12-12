import Foundation

@MainActor
class RoleplayScenarioDataModel {

    static let shared = RoleplayScenarioDataModel()

    private init() {}

    
    var scenarios: [RoleplayScenario] = [

        // -----------------------------------------------------------
        // 1. Grocery Shopping (already provided)
        // -----------------------------------------------------------

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
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 2. Making Friends
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Making Friends",
            description: "Learn how to start friendly conversations and introduce yourself.",
            imageURL: "MakingFriends",
            category: .custom,
            difficulty: .beginner,
            estimatedTimeMinutes: 3,
            script: [
                RoleplayMessage(sender: .app, text: "Hi! What's your name?", suggestedMessages: [
                    "My name is Harsh.",
                    "I’m sorry, could you repeat that?",
                    "Why are you asking?",
                    "Can we introduce ourselves again?"
                ]),
                RoleplayMessage(sender: .user, text: "Nice to meet you! What do you enjoy doing in your free time?", suggestedMessages: [
                    "I like reading and playing games.",
                    "I’m not sure, what about you?",
                    "Can you give me examples of hobbies?",
                    "I don’t have much free time."
                ]),
                RoleplayMessage(sender: .user, text: "That's cool! Do you usually hang out with friends on weekends?", suggestedMessages: [
                    "Yes, usually.",
                    "Not really, I prefer staying home.",
                    "It depends on my mood.",
                    "What do people normally do on weekends?"
                ]),
                RoleplayMessage(sender: .user, text: "Some people enjoy going to cafés or watching movies. Do you like those?", suggestedMessages: [
                    "Yes, I like movies.",
                    "I prefer outdoor activities.",
                    "I rarely go out.",
                    "What kind of movies do you like?"
                ]),
                RoleplayMessage(sender: .user, text: "I like comedies and adventure films. What about you?", suggestedMessages: [
                    "Comedies too!",
                    "I prefer action movies.",
                    "I like all genres.",
                    "I don’t watch many movies."
                ]),
                RoleplayMessage(sender: .user, text: "That’s interesting. We should talk about movies again sometime.", suggestedMessages: [
                    "Sure, that sounds great.",
                    "Maybe another time.",
                    "I’d like that.",
                    "Do you watch TV shows?"
                ]),
                RoleplayMessage(sender: .user, text: "Yes, I enjoy a few TV shows. It's fun sharing interests with new friends.", suggestedMessages: [
                    "I agree.",
                    "We’re friends now?",
                    "Thanks for chatting with me.",
                    "Do you meet new people often?"
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 3. Airport Check-in
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Airport Check-in",
            description: "Practice checking in at an airport counter smoothly.",
            imageURL: "AirportCheck-in",
            category: .travel,
            difficulty: .beginner,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(sender: .app, text: "May I see your passport?", suggestedMessages: [
                    "Sure, here it is.",
                    "I can’t find it. What should I do?",
                    "Do you accept digital passports?",
                    "Is this the right counter?"
                ]),
                RoleplayMessage(sender: .user, text: "Thank you. Are you checking in any luggage today?", suggestedMessages: [
                    "Yes, one suitcase.",
                    "No, just a carry-on.",
                    "What is the weight limit?",
                    "How much does extra baggage cost?"
                ]),
                RoleplayMessage(sender: .user, text: "Your bag looks fine. Do you prefer a window or aisle seat?", suggestedMessages: [
                    "Window, please.",
                    "Aisle seat.",
                    "Which one is better?",
                    "Is extra legroom available?"
                ]),
                RoleplayMessage(sender: .user, text: "I can put you in a window seat. Here is your boarding pass.", suggestedMessages: [
                    "Thank you.",
                    "Where is my gate?",
                    "Can you explain the boarding groups?",
                    "Is my flight on time?"
                ]),
                RoleplayMessage(sender: .user, text: "Your gate is A12, and your flight is on schedule.", suggestedMessages: [
                    "How long is the walk to A12?",
                    "Is there a food court nearby?",
                    "Where do I go for security?",
                    "Can I bring water through security?"
                ]),
                RoleplayMessage(sender: .user, text: "Security is down the hall. You'll need to empty water bottles before entering.", suggestedMessages: [
                    "Got it, thanks.",
                    "Is there a place to refill water?",
                    "Do I remove my laptop?",
                    "What time does boarding start?"
                ]),
                RoleplayMessage(sender: .user, text: "Boarding starts 30 minutes before departure. Have a safe trip!", suggestedMessages: [
                    "Thank you very much.",
                    "Can I upgrade my seat somewhere?",
                    "Where is the restroom?",
                    "Do you have flight Wi-Fi information?"
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 4. Ordering Food
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Ordering Food",
            description: "Learn how to place an order politely and clearly at a restaurant.",
            imageURL: "OrderingFood",
            category: .restaurant,
            difficulty: .intermediate,
            estimatedTimeMinutes: 3,
            script: [
                RoleplayMessage(sender: .app, text: "Welcome! What would you like to order today?", suggestedMessages: [
                    "I’d like a burger and fries.",
                    "What are your most popular dishes?",
                    "Do you have vegetarian options?",
                    "Can I see the drinks menu?"
                ]),
                RoleplayMessage(sender: .user, text: "Sure, we have several options. Would you like your burger with cheese?", suggestedMessages: [
                    "Yes, please.",
                    "No cheese for me.",
                    "Is there an extra charge?",
                    "What type of cheese do you use?"
                ]),
                RoleplayMessage(sender: .user, text: "We use cheddar. Would you like anything to drink with your meal?", suggestedMessages: [
                    "A soda, please.",
                    "Just water.",
                    "What juices do you have?",
                    "Can I get an iced tea?"
                ]),
                RoleplayMessage(sender: .user, text: "Great! Do you need any sauces with your fries?", suggestedMessages: [
                    "Ketchup, please.",
                    "Mayonnaise.",
                    "What sauces do you recommend?",
                    "No sauce, thank you."
                ]),
                RoleplayMessage(sender: .user, text: "Perfect. Would you like dessert after the meal?", suggestedMessages: [
                    "Maybe later.",
                    "What desserts do you have?",
                    "Not today.",
                    "Do you have ice cream?"
                ]),
                RoleplayMessage(sender: .user, text: "We have ice cream, cakes, and fruit bowls.", suggestedMessages: [
                    "I’ll try ice cream later.",
                    "Sounds good.",
                    "Do you have dairy-free dessert?",
                    "Can I see pictures of the desserts?"
                ]),
                RoleplayMessage(sender: .user, text: "Your order will be ready shortly. Enjoy your meal!", suggestedMessages: [
                    "Thank you!",
                    "How long will it take?",
                    "Can I change my drink?",
                    "Do you offer takeaway?"
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 5. Job Interview
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Job Interview",
            description: "Practice answering common job interview questions confidently.",
            imageURL: "JobInterview",
            category: .interview,
            difficulty: .advanced,
            estimatedTimeMinutes: 5,
            script: [
                RoleplayMessage(sender: .app, text: "Tell me about yourself.", suggestedMessages: [
                    "I’m a dedicated worker with experience in this field.",
                    "Can I focus on my work background?",
                    "What would you like to know specifically?",
                    "Should I talk about personal interests too?"
                ]),
                RoleplayMessage(sender: .user, text: "Thank you. What are your strongest skills?", suggestedMessages: [
                    "Problem-solving and communication.",
                    "I work well under pressure.",
                    "I’m good at teamwork and planning.",
                    "Can you give me examples of skills you value here?"
                ]),
                RoleplayMessage(sender: .user, text: "Good. Now, tell me about a weakness you’re working on.", suggestedMessages: [
                    "I sometimes take on too much responsibility.",
                    "I am improving my time management.",
                    "I get nervous speaking publicly.",
                    "Is it okay to mention soft skills?"
                ]),
                RoleplayMessage(sender: .user, text: "How do you handle conflict at work?", suggestedMessages: [
                    "I listen first and respond calmly.",
                    "I try to find compromise.",
                    "I involve a supervisor when needed.",
                    "It depends on the situation."
                ]),
                RoleplayMessage(sender: .user, text: "What interests you about this position?", suggestedMessages: [
                    "The role aligns with my career goals.",
                    "I like the challenges it offers.",
                    "Your company values appeal to me.",
                    "I want opportunities for growth."
                ]),
                RoleplayMessage(sender: .user, text: "Do you have any questions for us?", suggestedMessages: [
                    "What does a typical day look like?",
                    "How do you measure success?",
                    "What are the next steps?",
                    "Who will I work with closely?"
                ]),
                RoleplayMessage(sender: .user, text: "Thank you for your time. We’ll contact you soon.", suggestedMessages: [
                    "Thank you. I look forward to hearing from you.",
                    "I appreciate the interview.",
                    "Have a great day.",
                    "Can I reach out if I have more questions?"
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 6. Birthday Celebration
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Birthday Celebration",
            description: "Learn how to talk and interact during a birthday event.",
            imageURL: "BirthdayCelebration",
            category: .custom,
            difficulty: .intermediate,
            estimatedTimeMinutes: 2,
            script: [
                RoleplayMessage(sender: .app, text: "Would you like some cake?", suggestedMessages: [
                    "Yes, please!",
                    "Maybe just a small slice.",
                    "Not right now, thank you.",
                    "What flavor is it?"
                ]),
                RoleplayMessage(sender: .user, text: "It’s chocolate with strawberries on top.", suggestedMessages: [
                    "That sounds delicious!",
                    "Do you have vanilla?",
                    "Who made the cake?",
                    "Is it very sweet?"
                ]),
                RoleplayMessage(sender: .user, text: "Feel free to grab a plate. There are drinks on the table too.", suggestedMessages: [
                    "Great, I’ll take a drink.",
                    "What drinks are available?",
                    "Do you have juice?",
                    "Is everything self-serve?"
                ]),
                RoleplayMessage(sender: .user, text: "There’s soda, juice, and water.", suggestedMessages: [
                    "I’ll take juice.",
                    "Thanks for the options!",
                    "Do you have any snacks too?",
                    "Is this a big party?"
                ]),
                RoleplayMessage(sender: .user, text: "Yes, snacks are over there near the balloons.", suggestedMessages: [
                    "I’ll check them out.",
                    "Who decorated the place?",
                    "Do you need help setting anything up?",
                    "When do we sing happy birthday?"
                ]),
                RoleplayMessage(sender: .user, text: "We’ll sing soon when the birthday person arrives.", suggestedMessages: [
                    "I’m excited.",
                    "Should I bring a gift?",
                    "Can I take photos?",
                    "Where should I sit?"
                ]),
                RoleplayMessage(sender: .user, text: "Sit anywhere you like. Make yourself comfortable!", suggestedMessages: [
                    "Thank you.",
                    "This party feels fun.",
                    "Is anyone I know here?",
                    "Should I join a group to chat?"
                ])
            ]
        ),

        // -----------------------------------------------------------
        // 7. Hotel Booking
        // -----------------------------------------------------------

        RoleplayScenario(
            title: "Hotel Booking",
            description: "Practice speaking to a hotel receptionist for booking a room.",
            imageURL: "HotelBooking",
            category: .travel,
            difficulty: .intermediate,
            estimatedTimeMinutes: 4,
            script: [
                RoleplayMessage(sender: .app, text: "Do you have a reservation?", suggestedMessages: [
                    "No, I’d like to book a room.",
                    "Yes, I booked online.",
                    "Can you check under my name?",
                    "Do you have availability tonight?"
                ]),
                RoleplayMessage(sender: .user, text: "Certainly. What kind of room would you prefer?", suggestedMessages: [
                    "A single room.",
                    "A double, please.",
                    "What are the prices?",
                    "Do you have rooms with a view?"
                ]),
                RoleplayMessage(sender: .user, text: "We have both standard and deluxe options.", suggestedMessages: [
                    "What’s the difference?",
                    "I’ll take the standard.",
                    "How much is the deluxe?",
                    "Can I see photos?"
                ]),
                RoleplayMessage(sender: .user, text: "The deluxe has more space and includes breakfast.", suggestedMessages: [
                    "Breakfast sounds good.",
                    "I prefer something cheaper.",
                    "Is breakfast optional?",
                    "What time is breakfast served?"
                ]),
                RoleplayMessage(sender: .user, text: "Breakfast is from 7 AM to 10 AM.", suggestedMessages: [
                    "That works for me.",
                    "Do you have earlier options?",
                    "Is room service available?",
                    "What about late checkout?"
                ]),
                RoleplayMessage(sender: .user, text: "Late checkout is available for an extra fee.", suggestedMessages: [
                    "Good to know.",
                    "How much is the fee?",
                    "Can I decide later?",
                    "Is luggage storage free?"
                ]),
                RoleplayMessage(sender: .user, text: "Yes, we can store luggage for free. May I see your ID?", suggestedMessages: [
                    "Here it is.",
                    "Why do you need ID?",
                    "Can I use a passport instead?",
                    "Is digital ID accepted?"
                ]),
                RoleplayMessage(sender: .user, text: "All set. How would you like to pay?", suggestedMessages: [
                    "Card, please.",
                    "Can I pay cash?",
                    "Do you accept mobile payment?",
                    "Can I pay at checkout?"
                ]),
                RoleplayMessage(sender: .user, text: "Your room is booked. Enjoy your stay!", suggestedMessages: [
                    "Thank you!",
                    "Where is the elevator?",
                    "Can you tell me the Wi-Fi password?",
                    "What time does the pool open?"
                ])
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



