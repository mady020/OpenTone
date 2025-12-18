
import Foundation


var scenarios: [RoleplayScenario] = [
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
    RoleplayScenario(
        title: "Making Friends",
        description: "Practice starting conversations, finding common interests, and building friendships.",
        imageURL: "MakingFriends",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
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
                text: "Oh nice! What brings you here?",
                replyOptions: [
                    "I recently moved to this area.",
                    "I just joined this place.",
                    "I came with a friend.",
                    "I was curious and wanted to check it out."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "That’s great. What do you usually do in your free time?",
                replyOptions: [
                    "I like watching movies and series.",
                    "I enjoy playing sports.",
                    "I usually read or listen to music.",
                    "I like exploring new places."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Oh nice! What kind of movies do you like?",
                replyOptions: [
                    "I enjoy action and thrillers.",
                    "I like romantic movies.",
                    "Comedy is my favorite.",
                    "I enjoy documentaries."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "That’s interesting. Do you watch movies alone or with friends?",
                replyOptions: [
                    "Mostly with friends.",
                    "Usually alone.",
                    "It depends on the movie.",
                    "Both, actually."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Cool! Are you from this city?",
                replyOptions: [
                    "Yes, I grew up here.",
                    "No, I moved here recently.",
                    "I’m here for studies.",
                    "I’m here for work."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "How are you finding the city so far?",
                replyOptions: [
                    "I really like it here.",
                    "It's still new to me.",
                    "People seem friendly.",
                    "I'm still exploring."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "That’s good to hear. Have you made any friends yet?",
                replyOptions: [
                    "Not many, but I'm trying.",
                    "Yes, a few already.",
                    "Not yet, honestly.",
                    "I'm hoping to make some soon."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Well, it was really nice talking to you.",
                replyOptions: [
                    "Nice talking to you too!",
                    "I enjoyed this conversation.",
                    "Hope we meet again.",
                    "Let’s talk again sometime."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like to stay in touch?",
                replyOptions: [
                    "Sure, that would be great!",
                    "Yes, why not?",
                    "Of course!",
                    "I’d like that."
                ]
            )
        ]
    )
,
    RoleplayScenario(
        title: "Airport Check-in",
        description: "Practice check-in conversation at an airport counter.",
        imageURL: "AirportCheck-in",
        category: .travel,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [

            RoleplayMessage(
                speaker: .npc,
                text: "Good morning. May I see your passport and ticket, please?",
                replyOptions: [
                    "Sure, here you go.",
                    "Yes, one moment please.",
                    "Here are my passport and ticket.",
                    "I have my ticket on my phone."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Thank you. Where are you flying today?",
                replyOptions: [
                    "I’m flying to New York.",
                    "My destination is London.",
                    "I’m going to Dubai.",
                    "I have a connecting flight to Paris."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Is this a one-way ticket or a round trip?",
                replyOptions: [
                    "It’s a round-trip ticket.",
                    "One-way ticket.",
                    "I’ll be returning next week.",
                    "I have a return flight booked."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Do you have any luggage to check in?",
                replyOptions: [
                    "Yes, I have one suitcase.",
                    "I have two bags to check in.",
                    "No, just hand luggage.",
                    "Only a carry-on bag."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Please place your luggage on the scale.",
                replyOptions: [
                    "Sure.",
                    "Okay, here it is.",
                    "One moment.",
                    "Is this fine?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Your bag is slightly overweight.",
                replyOptions: [
                    "How much extra do I need to pay?",
                    "Can I remove some items?",
                    "Is there any allowance?",
                    "Can I transfer items to my carry-on?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like to pay the extra fee or rearrange your luggage?",
                replyOptions: [
                    "I’ll rearrange my luggage.",
                    "I’ll pay the extra fee.",
                    "Can you tell me the charges?",
                    "I’ll remove some items."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Do you prefer a window seat or an aisle seat?",
                replyOptions: [
                    "I’d prefer a window seat.",
                    "An aisle seat, please.",
                    "Any seat is fine.",
                    "Do you have extra legroom seats?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like to add priority boarding?",
                replyOptions: [
                    "Yes, please.",
                    "No, thank you.",
                    "What are the benefits?",
                    "Is there an extra charge?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Here is your boarding pass. Boarding starts at 9:30 AM.",
                replyOptions: [
                    "Thank you.",
                    "Which gate should I go to?",
                    "What time does boarding close?",
                    "Where is the security check?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Your gate number is 24B, and security is straight ahead.",
                replyOptions: [
                    "Thanks for your help.",
                    "How long will security take?",
                    "Is there a lounge nearby?",
                    "Where can I find restrooms?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Have a pleasant flight!",
                replyOptions: [
                    "Thank you very much!",
                    "Have a nice day.",
                    "Thanks, goodbye!",
                    "See you next time."
                ]
            )
        ]
    )
,
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
                    "Yes, please.",
                    "Sure.",
                    "One moment, please.",
                    "Can I see the menu first?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Here is the menu. Let me know if you need any help.",
                replyOptions: [
                    "Thank you.",
                    "I appreciate it.",
                    "Thanks.",
                    "Sure."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like something to drink?",
                replyOptions: [
                    "Yes, I’ll have water.",
                    "A soft drink, please.",
                    "I’d like a coffee.",
                    "No, thank you."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Are you ready to place your order?",
                replyOptions: [
                    "Yes, I am.",
                    "Almost, give me a moment.",
                    "Yes, I’d like to order now.",
                    "I need a little more time."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "What would you like to have?",
                replyOptions: [
                    "I’ll have the pasta.",
                    "I’d like the grilled chicken.",
                    "I’ll order a vegetarian dish.",
                    "I’d like today’s special."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like any sides with that?",
                replyOptions: [
                    "Yes, fries please.",
                    "A side salad, please.",
                    "No sides for me.",
                    "What do you recommend?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "How would you like your food prepared?",
                replyOptions: [
                    "Medium, please.",
                    "Well done.",
                    "Lightly cooked.",
                    "No special preference."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Alright, I’ll place your order now.",
                replyOptions: [
                    "Thank you.",
                    "Sounds good.",
                    "Great.",
                    "Perfect."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Your food will be served shortly.",
                replyOptions: [
                    "Thank you!",
                    "I appreciate it.",
                    "Looking forward to it.",
                    "Thanks a lot."
                ]
            )
        ]
    )
,
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
                text: "Good morning. Please have a seat.",
                replyOptions: [
                    "Good morning, thank you.",
                    "Thank you for having me.",
                    "Nice to meet you.",
                    "Good morning."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Can you tell me a little about yourself?",
                replyOptions: [
                    "I'm a motivated and hardworking individual.",
                    "I recently graduated and enjoy learning new skills.",
                    "I have experience relevant to this role.",
                    "I'm passionate about my career."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Why do you want to work for our company?",
                replyOptions: [
                    "I admire your company culture.",
                    "Your work aligns with my skills.",
                    "I see growth opportunities here.",
                    "I respect your organization."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "What are your strengths?",
                replyOptions: [
                    "I'm a good communicator.",
                    "I adapt quickly to new environments.",
                    "I'm very organized.",
                    "I'm a team player."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "What is one of your weaknesses?",
                replyOptions: [
                    "I sometimes focus too much on details.",
                    "I am learning to delegate better.",
                    "I used to be shy, but I'm improving.",
                    "I take time to adjust initially."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Where do you see yourself in five years?",
                replyOptions: [
                    "Growing professionally in this field.",
                    "Taking on more responsibilities.",
                    "Developing leadership skills.",
                    "Working with a great team."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Do you have any questions for us?",
                replyOptions: [
                    "What does a typical day look like?",
                    "What are the growth opportunities?",
                    "How do you measure success?",
                    "What is the next step?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Thank you for coming in today. We’ll be in touch.",
                replyOptions: [
                    "Thank you for your time.",
                    "I appreciate the opportunity.",
                    "Looking forward to hearing from you.",
                    "Have a great day."
                ]
            )
        ]
    ),
    RoleplayScenario(
        title: "Hotel Booking",
        description: "Practice booking a hotel room, asking about facilities, pricing, and check-in details.",
        imageURL: "HotelBooking",
        category: .travel,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [

            RoleplayMessage(
                speaker: .npc,
                text: "Good evening! Welcome to our hotel. How may I help you?",
                replyOptions: [
                    "Hi, I would like to book a room.",
                    "Hello, I need accommodation for tonight.",
                    "Good evening, do you have any rooms available?",
                    "I want to check availability for a room."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Sure. How many nights will you be staying?",
                replyOptions: [
                    "I will be staying for two nights.",
                    "Just one night.",
                    "Three nights, please.",
                    "I’m not sure yet."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "How many guests will be staying in the room?",
                replyOptions: [
                    "Just one person.",
                    "Two adults.",
                    "Two adults and one child.",
                    "I will be alone."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Would you like a single room or a double room?",
                replyOptions: [
                    "A single room, please.",
                    "I would prefer a double room.",
                    "Any room is fine.",
                    "What is the difference between them?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Our double room costs ₹3,500 per night and includes breakfast.",
                replyOptions: [
                    "That sounds good.",
                    "Is breakfast complimentary?",
                    "Do you have any discounts available?",
                    "Is there a cheaper option?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Yes, breakfast is included, and we also have free Wi-Fi.",
                replyOptions: [
                    "Great! Does the room have air conditioning?",
                    "Is room service available?",
                    "Do you have a swimming pool?",
                    "Is Wi-Fi available in the rooms?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Yes, all rooms are air-conditioned and room service is available 24/7.",
                replyOptions: [
                    "Perfect, I’ll take the room.",
                    "That sounds comfortable.",
                    "Can I see the room first?",
                    "Do you have a gym facility?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Sure. May I please see your ID for check-in?",
                replyOptions: [
                    "Here is my ID.",
                    "Sure, here you go.",
                    "Is a passport acceptable?",
                    "I have my ID on my phone."
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Thank you. How would you like to make the payment?",
                replyOptions: [
                    "I’ll pay by card.",
                    "Can I pay in cash?",
                    "Is UPI accepted?",
                    "Can I pay at checkout?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Your room is on the third floor. Here is your key card.",
                replyOptions: [
                    "Thank you very much.",
                    "What time is breakfast served?",
                    "What is the check-out time?",
                    "Can I get help with my luggage?"
                ]
            ),

            RoleplayMessage(
                speaker: .npc,
                text: "Breakfast is served from 7 AM to 10 AM, and check-out is at 11 AM.",
                replyOptions: [
                    "That’s perfect, thank you.",
                    "Can I request a late check-out?",
                    "Is there a wake-up call service?",
                    "Who should I contact for assistance?"
                ]
            )

        ]
    )

]
