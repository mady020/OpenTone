
import Foundation


let scenarios: [RoleplayScenario] = [
    RoleplayScenario(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
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
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
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
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
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
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
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
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
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
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
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
    ),

    
    RoleplayScenario(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        title: "Coffee Shop",
        description: "Practice ordering coffee, snacks, and chatting with the barista.",
        imageURL: "CoffeeShop",
        category: .restaurant,
        difficulty: .beginner,
        estimatedTimeMinutes: 3,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hi! What can I get for you today?", replyOptions: ["I'd like a cappuccino, please.", "Can I get a large iced latte?", "What do you recommend?", "Just a drip coffee for me."]),
            RoleplayMessage(speaker: .npc, text: "Sure thing. Would you like anything to eat with that?", replyOptions: ["Yes, a chocolate croissant.", "No, just the drink.", "Do you have gluten-free muffins?", "I'll take a blueberry bagel."]),
            RoleplayMessage(speaker: .npc, text: "Got it. Is that for here or to go?", replyOptions: ["To go.", "For here, please.", "I'll be staying.", "Can you put it in a to-go cup, but I'll sit down?"]),
            RoleplayMessage(speaker: .npc, text: "Alright. That will be $6.50. You can pay with card or cash.", replyOptions: ["I'll use my card.", "Here’s a ten-dollar bill.", "Do you take mobile pay?", "Keep the change."]),
            RoleplayMessage(speaker: .npc, text: "Thank you! I'll have that right out for you at the end of the counter.", replyOptions: ["Thanks!", "Great, I'll wait over there.", "Perfect.", "Have a good day!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        title: "Doctor's Appointment",
        description: "Checking in at the clinic and describing your symptoms.",
        imageURL: "DoctorAppointment",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            RoleplayMessage(speaker: .npc, text: "Good morning. Do you have an appointment?", replyOptions: ["Yes, under John Smith.", "I have an appointment at 10 AM.", "No, I'm a walk-in. Is that okay?", "Yes, I booked it online yesterday."]),
            RoleplayMessage(speaker: .npc, text: "I see it. Please fill out this form and have a seat.", replyOptions: ["Sure, I'll do that now.", "Do I need a pen?", "How long is the wait?", "I filled this out online, do I still need to?"]),
            RoleplayMessage(speaker: .npc, text: "The doctor will see you now. What seems to be the problem today?", replyOptions: ["I've had a bad cough for a week.", "My stomach has been hurting.", "I just need a general check-up.", "I hurt my ankle running."]),
            RoleplayMessage(speaker: .npc, text: "I see. Are you taking any medications currently?", replyOptions: ["No, nothing.", "Just some over-the-counter painkillers.", "Yes, I take blood pressure medication.", "I take multivitamins."]),
            RoleplayMessage(speaker: .npc, text: "Okay, we're going to order some tests. The nurse will draw blood shortly.", replyOptions: ["Okay, sounds good.", "Will that hurt?", "How long do results take?", "Can I eat after the test?"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        title: "Asking for Directions",
        description: "Practice getting around the city by asking locals for directions.",
        imageURL: "Directions",
        category: .travel,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Excuse me, are you lost? Do you need help?", replyOptions: ["Yes, can you tell me where the train station is?", "I'm looking for the art museum.", "Do you know where the nearest ATM is?", "Yes, I'm trying to find Main Street."]),
            RoleplayMessage(speaker: .npc, text: "Oh, the train station is just a few blocks away. You need to go straight down this road.", replyOptions: ["Go straight, then what?", "How far is it?", "Is it a long walk?", "Can I take a bus from here?"]),
            RoleplayMessage(speaker: .npc, text: "It's about a five-minute walk. Once you see the big park, turn left.", replyOptions: ["Turn left at the park. Got it.", "Is the park on the left or right side?", "Thank you so much!", "Will I be able to see it from the corner?"]),
            RoleplayMessage(speaker: .npc, text: "Yes, you can't miss it. It's a huge building with a clock tower.", replyOptions: ["Perfect, I appreciate the help.", "Thanks! Have a great day.", "That sounds easy enough.", "You've been very helpful."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        title: "Lost Luggage",
        description: "Report missing baggage at the airport service desk.",
        imageURL: "LostLuggage",
        category: .travel,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            RoleplayMessage(speaker: .npc, text: "Baggage Services, how can I help you?", replyOptions: ["My suitcase didn't arrive on the carousel.", "I can't find my bags.", "I need to file a missing luggage report.", "Where do oversized bags come out?"]),
            RoleplayMessage(speaker: .npc, text: "I'm sorry to hear that. Can I see your boarding pass and baggage tag receipts?", replyOptions: ["Here they are.", "I think I lost the receipts.", "I only have my boarding pass.", "Sure, let me find them."]),
            RoleplayMessage(speaker: .npc, text: "Could you describe the bag for me? What color and brand is it?", replyOptions: ["It's a large black Samsonite suitcase.", "A medium-sized red duffel bag.", "It's blue with a bright yellow tag.", "A hard-shell silver case."]),
            RoleplayMessage(speaker: .npc, text: "We will trace it immediately. Can we get an address to deliver it to once we find it?", replyOptions: ["Yes, I'm staying at the Marriott downtown.", "Can I just come back to pick it up?", "I live locally, here's my address.", "How long will this take?"]),
            RoleplayMessage(speaker: .npc, text: "Usually it arrives on the next flight. We will call you as soon as it lands.", replyOptions: ["Okay, here is my phone number.", "Do you offer compensation for essentials?", "Thank you for your help.", "I hope it turns up soon."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        title: "Small Talk at a Party",
        description: "Making casual conversation with strangers at a social gathering.",
        imageURL: "PartyTalk",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 5,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hi! I don't think we've met. I'm Alex.", replyOptions: ["Hi Alex, I'm Sarah. Nice to meet you.", "Hey, nice to meet you. I'm Mark.", "Hello! Are you a friend of the host?", "Great party, isn't it? I'm Lisa."]),
            RoleplayMessage(speaker: .npc, text: "Nice to meet you. So, how do you know the host?", replyOptions: ["We went to college together.", "We work in the same office.", "I'm actually a friend of their roommate.", "We met at a networking event a while back."]),
            RoleplayMessage(speaker: .npc, text: "Oh, that's cool! I'm an old friend from high school. What do you do for work?", replyOptions: ["I'm a software engineer.", "I work in marketing.", "I'm currently studying biology.", "I'm a teacher."]),
            RoleplayMessage(speaker: .npc, text: "Wow, that sounds really interesting! Is it a challenging job?", replyOptions: ["Yes, it can be, but I love it.", "It has its moments.", "Not too bad, usually keeps me busy.", "It's quite demanding, to be honest."]),
            RoleplayMessage(speaker: .npc, text: "I can imagine. Anyways, I'm going to grab a drink. It was lovely talking to you!", replyOptions: ["You too! See you around.", "Catch you later!", "Grab me one too, if you don't mind!", "Nice speaking with you."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        title: "Tech Support Call",
        description: "Call customer service because your internet is down.",
        imageURL: "TechSupport",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 6,
        script: [
            RoleplayMessage(speaker: .npc, text: "Thank you for calling Technical Support. This is Sarah. How can I assist you?", replyOptions: ["My internet is not working.", "My router is flashing red.", "I have no Wi-Fi connection.", "My download speed is extremely slow."]),
            RoleplayMessage(speaker: .npc, text: "I'm sorry to hear that. Can I have your account number or phone number?", replyOptions: ["My phone number is 555-1234.", "My account number is 987654321.", "I don't know my account number.", "Can you look it up by my name?"]),
            RoleplayMessage(speaker: .npc, text: "Thank you. I see your account. Have you tried restarting your router?", replyOptions: ["Yes, I disconnected it for a minute.", "No, how do I do that?", "I restarted it but it didn't help.", "Let me try that now."]),
            RoleplayMessage(speaker: .npc, text: "I see an outage in your area that our technicians are fixing. It should be up in two hours.", replyOptions: ["Ah, that makes sense. Thank you.", "Will I be compensated for the downtime?", "Is there any way to fix it sooner?", "Okay, I'll wait it out."]),
            RoleplayMessage(speaker: .npc, text: "Is there anything else I can assist you with today?", replyOptions: ["No, that's all. Thanks.", "When does my billing cycle end?", "Can I upgrade my speed?", "Nope, have a good day."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
        title: "Gym Membership",
        description: "Ask about gym prices, facilities, and getting a membership.",
        imageURL: "GymMembership",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 5,
        script: [
            RoleplayMessage(speaker: .npc, text: "Welcome to FitZone! Are you looking to sign up for a membership today?", replyOptions: ["Yes, I'm interested in joining.", "I just want some information first.", "How much is your monthly fee?", "Can I look around the gym?"]),
            RoleplayMessage(speaker: .npc, text: "Our standard membership is $40 a month. It includes all equipment and locker rooms.", replyOptions: ["Does it include fitness classes?", "Is there an joining fee?", "Can I cancel anytime?", "Do you have a personal trainer?"]),
            RoleplayMessage(speaker: .npc, text: "Classes are $10 extra per month. And yes, there's a $20 sign-up fee.", replyOptions: ["Okay, I'll take the standard membership.", "I want the classes included too.", "Are there any student discounts?", "Can I try a day pass first?"]),
            RoleplayMessage(speaker: .npc, text: "Great. I just need to scan your ID and get a card on file.", replyOptions: ["Here is my driver's license and credit card.", "Can I pay in cash?", "How soon can I start working out?", "Sure, here you go."]),
            RoleplayMessage(speaker: .npc, text: "You're all set! Here is your key fob. You can start right now if you want.", replyOptions: ["Awesome, thanks!", "Where are the locker rooms?", "Do I need to swipe this every time?", "Great, I'll go change."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
        title: "Return an Item",
        description: "Return a defective piece of clothing to a department store.",
        imageURL: "ReturnItem",
        category: .groceryShopping,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Next in line! How can I help you today?", replyOptions: ["I'd like to return this shirt.", "This sweater has a tear in it.", "I need to exchange this for a different size.", "I bought this yesterday but it doesn't fit."]),
            RoleplayMessage(speaker: .npc, text: "Do you have the receipt with you?", replyOptions: ["Yes, here it is.", "No, I threw it away.", "I have the digital receipt on my phone.", "It was a gift."]),
            RoleplayMessage(speaker: .npc, text: "Okay, since it's within 30 days, we can do a full refund. Did you want that on the original card?", replyOptions: ["Yes, please.", "Can I get store credit instead?", "Can I get cash back?", "Actually, I want to exchange it."]),
            RoleplayMessage(speaker: .npc, text: "Please go ahead and insert or tap your card on the terminal.", replyOptions: ["Tapping it now.", "Done.", "Did it go through?", "One second."]),
            RoleplayMessage(speaker: .npc, text: "Alright, your return is processed. The money should show up in 3 to 5 business days.", replyOptions: ["Thank you very much.", "Do I need to sign anything?", "Perfect, have a good day.", "Thanks for the help."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
        title: "Renting an Apartment",
        description: "Talk to a real estate agent about viewing and renting a flat.",
        imageURL: "RentingApartment",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hello, this is City Real Estate. Which property are you calling about?", replyOptions: ["I'm calling about the 2-bedroom on Elm Street.", "Do you have any studio apartments available?", "I want to schedule a viewing.", "I saw your listing online."]),
            RoleplayMessage(speaker: .npc, text: "Ah, the Elm Street property. Yes, the rent is $1,800 a month. When do you want to move in?", replyOptions: ["The first of next month.", "As soon as possible.", "In about two weeks.", "I'm flexible."]),
            RoleplayMessage(speaker: .npc, text: "Are you employed full-time? We require income to be 3x the monthly rent.", replyOptions: ["Yes, I work full-time.", "I am a student with a guarantor.", "I work freelance, but I can show bank statements.", "Yes."]),
            RoleplayMessage(speaker: .npc, text: "Good. Are there any pets moving in with you?", replyOptions: ["No pets.", "I have a small dog.", "Does a cat count?", "Are pets allowed?"]),
            RoleplayMessage(speaker: .npc, text: "Pets are fine with an additional deposit. I have an opening tomorrow at 3 PM to show you the place. Does that work?", replyOptions: ["3 PM is perfect.", "Can we do 5 PM instead?", "Is the weekend possible?", "Yes, I will be there."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        title: "Pharmacy Visit",
        description: "Ask a pharmacist for advice on cold medication and prescriptions.",
        imageURL: "Pharmacy",
        category: .groceryShopping,
        difficulty: .beginner,
        estimatedTimeMinutes: 3,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hi there. Picking up a prescription or do you need a recommendation?", replyOptions: ["I need something for a sore throat.", "I'm picking up a prescription for Sarah.", "Do you have allergy medicine?", "Where are the band-aids?"]),
            RoleplayMessage(speaker: .npc, text: "For a sore throat, I recommend these lozenges and some ibuprofen. Are you allergic to any medicines?", replyOptions: ["No, no allergies.", "I'm allergic to penicillin.", "Only allergic to pollen.", "I don't think so."]),
            RoleplayMessage(speaker: .npc, text: "Okay, these will work perfectly. Do you need anything else?", replyOptions: ["No, that's it.", "Where can I find cough syrup?", "Do you sell vitamins?", "That's all for today."]),
            RoleplayMessage(speaker: .npc, text: "You can pay for those right here at this register. It comes to $12.", replyOptions: ["Here's twenty.", "I'll use Apple Pay.", "Can I use my rewards card?", "Here you go."]),
            RoleplayMessage(speaker: .npc, text: "Thank you. Feel better soon!", replyOptions: ["Thanks!", "I hope so.", "Have a good one.", "I appreciate it."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
        title: "Bank Account Opening",
        description: "Visit a bank to open a new savings account and ask about interest rates.",
        imageURL: "BankAccount",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            RoleplayMessage(speaker: .npc, text: "Good morning! Welcome to City Bank. How can I help you today?", replyOptions: ["I'd like to open a savings account.", "I need information about your accounts.", "Can I open an account without an appointment?", "What documents do I need to open an account?"]),
            RoleplayMessage(speaker: .npc, text: "Sure! We have a few options. Would you prefer a basic savings account or a premium one?", replyOptions: ["What's the difference between them?", "I'll go with the basic one.", "What are the interest rates?", "Which one has no minimum balance?"]),
            RoleplayMessage(speaker: .npc, text: "The basic account has no minimum balance and offers 3% interest. I'll need your ID and proof of address.", replyOptions: ["Here is my ID and a utility bill.", "Can I use my passport?", "I have all my documents here.", "Do I need to bring anything else?"]),
            RoleplayMessage(speaker: .npc, text: "Perfect. I'll set up your account now. Would you like a debit card as well?", replyOptions: ["Yes, please.", "Is there an annual fee for the card?", "Can I get a contactless card?", "How long will it take to arrive?"]),
            RoleplayMessage(speaker: .npc, text: "Your account is now active! Here is your account number. The debit card will arrive in 5-7 days.", replyOptions: ["Thank you so much!", "Can I set up online banking too?", "Where is the nearest ATM?", "Great, I appreciate your help."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "B2B2B2B2-B2B2-B2B2-B2B2-B2B2B2B2B2B2")!,
        title: "Booking a Cab",
        description: "Practice calling or hailing a cab and giving directions to your destination.",
        imageURL: "BookingCab",
        category: .travel,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hello! Where would you like to go?", replyOptions: ["To the airport, please.", "Can you take me to Central Mall?", "I need to go to 45 Oak Street.", "How much to go downtown?"]),
            RoleplayMessage(speaker: .npc, text: "Sure, that'll take about 20 minutes. Do you have a preferred route?", replyOptions: ["Take the highway, it's faster.", "Any route is fine.", "Avoid the highway, please.", "Whichever has less traffic."]),
            RoleplayMessage(speaker: .npc, text: "No problem. Would you like me to turn on the AC?", replyOptions: ["Yes, please.", "No, I'm fine.", "Just a little, thanks.", "Can you open the window instead?"]),
            RoleplayMessage(speaker: .npc, text: "We're almost there. It's on your left side, right?", replyOptions: ["Yes, right here is perfect.", "A little further, please.", "Can you stop after the signal?", "Drop me at the main gate."]),
            RoleplayMessage(speaker: .npc, text: "Here we are. The fare is $18.", replyOptions: ["Here you go, keep the change.", "Can I pay by card?", "Do you have change for a fifty?", "Thanks for the ride!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "C3C3C3C3-C3C3-C3C3-C3C3-C3C3C3C3C3C3")!,
        title: "Library Visit",
        description: "Practice asking about books, library cards, and borrowing policies.",
        imageURL: "LibraryVisit",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Welcome to the public library! Can I help you find something?", replyOptions: ["I'm looking for books on science fiction.", "Where is the children's section?", "I'd like to get a library card.", "Do you have today's newspaper?"]),
            RoleplayMessage(speaker: .npc, text: "For a library card, I just need your ID and proof of residence. It's completely free!", replyOptions: ["Great, here's my ID.", "How many books can I borrow at a time?", "Is there a fee for late returns?", "Can I also borrow audiobooks?"]),
            RoleplayMessage(speaker: .npc, text: "You can borrow up to 5 books for 14 days. Late returns are $0.25 per day.", replyOptions: ["That's reasonable.", "Can I renew books online?", "What if I lose a book?", "Perfect, I'll sign up."]),
            RoleplayMessage(speaker: .npc, text: "Here is your library card. The fiction section is on the second floor.", replyOptions: ["Thank you so much!", "Do you have a reading room?", "Is there free Wi-Fi here?", "Can I also use the computers?"]),
            RoleplayMessage(speaker: .npc, text: "Yes, the reading room is upstairs and Wi-Fi is free. Enjoy your visit!", replyOptions: ["Thanks, I will!", "This is wonderful.", "I'll definitely come back.", "Have a great day!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "D4D4D4D4-D4D4-D4D4-D4D4-D4D4D4D4D4D4")!,
        title: "Noise Complaint",
        description: "Politely talk to a neighbor about noise at night.",
        imageURL: "NoiseComplaint",
        category: .custom,
        difficulty: .intermediate,
        estimatedTimeMinutes: 5,
        script: [
            RoleplayMessage(speaker: .npc, text: "Oh, hi! Can I help you with something?", replyOptions: ["Hi, I'm your neighbor from next door.", "Hey, I wanted to talk about last night.", "Sorry to bother you, but I need to discuss something.", "Hi there, do you have a minute?"]),
            RoleplayMessage(speaker: .npc, text: "Oh sure, what's up?", replyOptions: ["The music was quite loud last night.", "I could hear a lot of noise from your apartment.", "I couldn't sleep because of the party.", "Would it be possible to keep the volume down after 10 PM?"]),
            RoleplayMessage(speaker: .npc, text: "Oh, I'm really sorry about that! We had some friends over and lost track of time.", replyOptions: ["I understand, it happens.", "No worries, just wanted to let you know.", "Maybe just a heads-up next time?", "I appreciate you understanding."]),
            RoleplayMessage(speaker: .npc, text: "Absolutely, we'll keep it down in the future. Again, really sorry.", replyOptions: ["Thanks, I appreciate it.", "No hard feelings.", "Maybe we can exchange numbers in case it happens again?", "That's all I needed. Have a good day."]),
            RoleplayMessage(speaker: .npc, text: "Sounds good. And hey, you're welcome to join next time!", replyOptions: ["Ha, I might take you up on that!", "Thanks, that's kind of you.", "I'll think about it!", "Have a good one!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "E5E5E5E5-E5E5-E5E5-E5E5-E5E5E5E5E5E5")!,
        title: "Parent-Teacher Meeting",
        description: "Discuss your child's progress with their teacher.",
        imageURL: "ParentTeacher",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 7,
        script: [
            RoleplayMessage(speaker: .npc, text: "Good evening! You must be Aarav's parent. Please, have a seat.", replyOptions: ["Good evening. Yes, I'm Aarav's mother.", "Hello, thank you for meeting with me.", "Hi, I wanted to know how Aarav is doing.", "Good evening. How is my child performing?"]),
            RoleplayMessage(speaker: .npc, text: "Aarav is a very bright student. He does well in math and science, but struggles a bit with reading.", replyOptions: ["What can we do to improve his reading?", "Does he participate in class?", "Is he getting along with other students?", "Should I hire a tutor?"]),
            RoleplayMessage(speaker: .npc, text: "I'd suggest 20 minutes of daily reading at home. Also, he's very popular with classmates!", replyOptions: ["That's great to hear.", "We'll start a reading routine.", "Does the school have a reading program?", "Any book recommendations?"]),
            RoleplayMessage(speaker: .npc, text: "We do have an after-school reading club on Wednesdays. I think he'd enjoy it.", replyOptions: ["I'll sign him up.", "What time does it end?", "Is there a fee?", "That sounds perfect for him."]),
            RoleplayMessage(speaker: .npc, text: "Great! Feel free to reach out anytime. It was lovely meeting you.", replyOptions: ["Thank you for your time.", "I really appreciate your feedback.", "We'll work on the reading at home.", "Have a good evening!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "F6F6F6F6-F6F6-F6F6-F6F6-F6F6F6F6F6F6")!,
        title: "Train Ticket Booking",
        description: "Practice buying train tickets at the station counter.",
        imageURL: "TrainTicket",
        category: .travel,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Next, please. Where would you like to travel?", replyOptions: ["One ticket to Mumbai, please.", "I need two tickets to Delhi.", "What's the next train to Jaipur?", "How much is a ticket to Bangalore?"]),
            RoleplayMessage(speaker: .npc, text: "The next express leaves in 45 minutes. Would you like first class or standard?", replyOptions: ["Standard is fine.", "How much is first class?", "Is there a sleeper option?", "I'll take first class."]),
            RoleplayMessage(speaker: .npc, text: "Standard is $25 one-way. First class is $45. Which platform does it depart from?", replyOptions: ["I'll go with standard.", "Two standard tickets, please.", "Which platform is it?", "Can I book a round trip?"]),
            RoleplayMessage(speaker: .npc, text: "Platform 3. The train departs at 4:15 PM. Don't forget your ticket.", replyOptions: ["Thank you!", "Is there a waiting room?", "Where can I grab a coffee before the train?", "How long is the journey?"]),
            RoleplayMessage(speaker: .npc, text: "The journey is about 3 hours. There's a café on Platform 1. Have a safe trip!", replyOptions: ["Thanks, have a great day!", "I'll check out the café.", "Appreciate your help.", "See you!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "A7A7A7A7-A7A7-A7A7-A7A7-A7A7A7A7A7A7")!,
        title: "Emergency Call",
        description: "Practice reporting an emergency clearly and calmly over the phone.",
        imageURL: "EmergencyCall",
        category: .custom,
        difficulty: .advanced,
        estimatedTimeMinutes: 5,
        script: [
            RoleplayMessage(speaker: .npc, text: "911, what is your emergency?", replyOptions: ["There's been a car accident.", "I need an ambulance, someone fainted.", "I want to report a fire in my building.", "Someone broke into our house."]),
            RoleplayMessage(speaker: .npc, text: "Stay calm. Can you tell me your exact location?", replyOptions: ["I'm at the corner of Main and 5th.", "45 Elm Street, Apartment 12B.", "Near the Central Park entrance.", "I'm not sure of the address, but I can describe it."]),
            RoleplayMessage(speaker: .npc, text: "Help is on the way. Is anyone injured?", replyOptions: ["Yes, one person is hurt.", "No injuries, but people are scared.", "I'm not sure, I can't get close.", "Yes, they need medical attention."]),
            RoleplayMessage(speaker: .npc, text: "Stay on the line with me. Are you in a safe place?", replyOptions: ["Yes, I moved away from the area.", "I'm standing nearby watching.", "Not really, should I move?", "Yes, I'm inside a shop."]),
            RoleplayMessage(speaker: .npc, text: "Emergency services should be there in a few minutes. You did great calling this in.", replyOptions: ["Thank you.", "I can hear the sirens now.", "Should I stay here?", "Thanks for the help."])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "B8B8B8B8-B8B8-B8B8-B8B8-B8B8B8B8B8B8")!,
        title: "Salon Haircut",
        description: "Describe the haircut you want and chat with the hairstylist.",
        imageURL: "SalonHaircut",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hey! Welcome. Do you have an appointment?", replyOptions: ["No, I'm a walk-in. Is that okay?", "Yes, under the name Priya.", "I booked for 3 PM.", "No appointment. How long is the wait?"]),
            RoleplayMessage(speaker: .npc, text: "No worries, we can take you now. What are you looking for today?", replyOptions: ["Just a trim, please.", "I want to try something new.", "Can you suggest a style for my face shape?", "I'd like it shorter on the sides."]),
            RoleplayMessage(speaker: .npc, text: "Sure! How short do you want the sides? Fade, or just a little shorter?", replyOptions: ["A light fade, please.", "Just a little shorter, nothing drastic.", "I'll show you a picture.", "Whatever you think looks good."]),
            RoleplayMessage(speaker: .npc, text: "Looking great so far. Would you like any product in your hair?", replyOptions: ["Yes, some gel would be nice.", "No, I prefer it natural.", "What do you recommend?", "Just a little wax, please."]),
            RoleplayMessage(speaker: .npc, text: "All done! That'll be $20. You look fantastic.", replyOptions: ["Thank you, I love it!", "Here's $25, keep the change.", "Can I pay by card?", "You did an amazing job!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "C9C9C9C9-C9C9-C9C9-C9C9-C9C9C9C9C9C9")!,
        title: "Car Rental",
        description: "Rent a car for a road trip and learn about insurance options.",
        imageURL: "CarRental",
        category: .travel,
        difficulty: .intermediate,
        estimatedTimeMinutes: 6,
        script: [
            RoleplayMessage(speaker: .npc, text: "Welcome to DriveEasy Rentals! How can I help you?", replyOptions: ["I'd like to rent a car for 3 days.", "What SUVs do you have available?", "I need a car for a weekend trip.", "Do you have any economy cars?"]),
            RoleplayMessage(speaker: .npc, text: "We have a compact sedan for $45/day and an SUV for $75/day. Both include unlimited mileage.", replyOptions: ["I'll take the sedan.", "Does the SUV have GPS?", "Is insurance included?", "Are there any current promotions?"]),
            RoleplayMessage(speaker: .npc, text: "Insurance is optional. Basic coverage is $12/day and full coverage is $20/day.", replyOptions: ["I'll go with basic coverage.", "Full coverage, please.", "Does my credit card cover it?", "I'll skip the insurance."]),
            RoleplayMessage(speaker: .npc, text: "I'll need your driver's license and a credit card for the deposit.", replyOptions: ["Here they are.", "How much is the deposit?", "Can I use a debit card?", "Sure, one moment."]),
            RoleplayMessage(speaker: .npc, text: "You're all set! The car is in spot B7. Please return it with a full tank.", replyOptions: ["Got it, thank you!", "Where is the nearest gas station?", "What if I return it late?", "Thanks for your help!"])
        ]
    ),
    RoleplayScenario(
        id: UUID(uuidString: "D0D0D0D0-D0D0-D0D0-D0D0-D0D0D0D0D0D0")!,
        title: "Post Office Visit",
        description: "Send a package and buy stamps at the post office.",
        imageURL: "PostOffice",
        category: .custom,
        difficulty: .beginner,
        estimatedTimeMinutes: 4,
        script: [
            RoleplayMessage(speaker: .npc, text: "Hello! What can I do for you today?", replyOptions: ["I need to send this package.", "I'd like to buy some stamps.", "How much does it cost to ship internationally?", "I need to pick up a registered letter."]),
            RoleplayMessage(speaker: .npc, text: "Let me weigh that for you. Where is it going?", replyOptions: ["It's going to New York.", "Shipping to London, UK.", "It's a domestic package to Chennai.", "To my parents in Bangalore."]),
            RoleplayMessage(speaker: .npc, text: "That'll be $14 for standard delivery or $22 for express. Express arrives in 2 days.", replyOptions: ["I'll go with express.", "Standard is fine.", "How long does standard take?", "Can I track the package?"]),
            RoleplayMessage(speaker: .npc, text: "Yes, you'll get a tracking number. Please fill out this form with the sender and recipient details.", replyOptions: ["Sure, here you go.", "Do I need to declare the contents?", "Can I insure the package?", "Is there a fragile label?"]),
            RoleplayMessage(speaker: .npc, text: "All done! Here's your receipt and tracking number. Have a great day!", replyOptions: ["Thank you!", "How do I track it online?", "Thanks, you too!", "I appreciate your help."])
        ]
    )
]
