import UIKit

/// Shared card style data used by the Roleplays tab, Dashboard, and Detail screen.
struct CardStyle {
    let iconName: String
    let gradientColors: [UIColor]
}

struct CardStyleProvider {

    static let styles: [String: CardStyle] = [
        "Grocery Shopping": CardStyle(
            iconName: "cart.fill",
            gradientColors: [UIColor(red: 0.66, green: 0.90, blue: 0.81, alpha: 1.0),
                             UIColor(red: 0.34, green: 0.77, blue: 0.59, alpha: 1.0)]
        ),
        "Making Friends": CardStyle(
            iconName: "bubble.left.and.bubble.right.fill",
            gradientColors: [UIColor(red: 0.83, green: 0.65, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.61, green: 0.45, blue: 0.81, alpha: 1.0)]
        ),
        "Airport Check-in": CardStyle(
            iconName: "airplane",
            gradientColors: [UIColor(red: 0.54, green: 0.81, blue: 0.94, alpha: 1.0),
                             UIColor(red: 0.36, green: 0.61, blue: 0.84, alpha: 1.0)]
        ),
        "Ordering Food": CardStyle(
            iconName: "fork.knife",
            gradientColors: [UIColor(red: 1.00, green: 0.83, blue: 0.65, alpha: 1.0),
                             UIColor(red: 1.00, green: 0.64, blue: 0.42, alpha: 1.0)]
        ),
        "Job Interview": CardStyle(
            iconName: "briefcase.fill",
            gradientColors: [UIColor(red: 0.72, green: 0.78, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.48, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Hotel Booking": CardStyle(
            iconName: "bed.double.fill",
            gradientColors: [UIColor(red: 1.00, green: 0.71, blue: 0.76, alpha: 1.0),
                             UIColor(red: 0.95, green: 0.55, blue: 0.62, alpha: 1.0)]
        ),
        "Coffee Shop": CardStyle(
            iconName: "cup.and.saucer.fill",
            gradientColors: [UIColor(red: 0.76, green: 0.60, blue: 0.42, alpha: 1.0),
                             UIColor(red: 0.55, green: 0.38, blue: 0.24, alpha: 1.0)]
        ),
        "Doctor's Appointment": CardStyle(
            iconName: "stethoscope",
            gradientColors: [UIColor(red: 0.55, green: 0.86, blue: 0.78, alpha: 1.0),
                             UIColor(red: 0.30, green: 0.70, blue: 0.60, alpha: 1.0)]
        ),
        "Asking for Directions": CardStyle(
            iconName: "map.fill",
            gradientColors: [UIColor(red: 0.40, green: 0.73, blue: 0.90, alpha: 1.0),
                             UIColor(red: 0.22, green: 0.53, blue: 0.78, alpha: 1.0)]
        ),
        "Lost Luggage": CardStyle(
            iconName: "suitcase.fill",
            gradientColors: [UIColor(red: 0.90, green: 0.62, blue: 0.62, alpha: 1.0),
                             UIColor(red: 0.75, green: 0.40, blue: 0.40, alpha: 1.0)]
        ),
        "Small Talk at a Party": CardStyle(
            iconName: "party.popper.fill",
            gradientColors: [UIColor(red: 1.00, green: 0.75, blue: 0.50, alpha: 1.0),
                             UIColor(red: 0.95, green: 0.55, blue: 0.30, alpha: 1.0)]
        ),
        "Tech Support Call": CardStyle(
            iconName: "headphones",
            gradientColors: [UIColor(red: 0.45, green: 0.55, blue: 0.75, alpha: 1.0),
                             UIColor(red: 0.30, green: 0.40, blue: 0.65, alpha: 1.0)]
        ),
        "Gym Membership": CardStyle(
            iconName: "dumbbell.fill",
            gradientColors: [UIColor(red: 0.95, green: 0.50, blue: 0.50, alpha: 1.0),
                             UIColor(red: 0.82, green: 0.30, blue: 0.30, alpha: 1.0)]
        ),
        "Return an Item": CardStyle(
            iconName: "arrow.uturn.left.circle.fill",
            gradientColors: [UIColor(red: 0.60, green: 0.80, blue: 0.55, alpha: 1.0),
                             UIColor(red: 0.40, green: 0.65, blue: 0.38, alpha: 1.0)]
        ),
        "Renting an Apartment": CardStyle(
            iconName: "house.fill",
            gradientColors: [UIColor(red: 0.55, green: 0.70, blue: 0.90, alpha: 1.0),
                             UIColor(red: 0.38, green: 0.52, blue: 0.78, alpha: 1.0)]
        ),
        "Pharmacy Visit": CardStyle(
            iconName: "cross.case.fill",
            gradientColors: [UIColor(red: 0.42, green: 0.82, blue: 0.66, alpha: 1.0),
                             UIColor(red: 0.25, green: 0.68, blue: 0.50, alpha: 1.0)]
        ),
        "Bank Account Opening": CardStyle(
            iconName: "banknote.fill",
            gradientColors: [UIColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),
                             UIColor(red: 0.18, green: 0.55, blue: 0.42, alpha: 1.0)]
        ),
        "Booking a Cab": CardStyle(
            iconName: "car.fill",
            gradientColors: [UIColor(red: 1.00, green: 0.82, blue: 0.30, alpha: 1.0),
                             UIColor(red: 0.92, green: 0.68, blue: 0.15, alpha: 1.0)]
        ),
        "Library Visit": CardStyle(
            iconName: "books.vertical.fill",
            gradientColors: [UIColor(red: 0.68, green: 0.55, blue: 0.82, alpha: 1.0),
                             UIColor(red: 0.50, green: 0.38, blue: 0.70, alpha: 1.0)]
        ),
        "Noise Complaint": CardStyle(
            iconName: "speaker.wave.3.fill",
            gradientColors: [UIColor(red: 0.85, green: 0.55, blue: 0.55, alpha: 1.0),
                             UIColor(red: 0.72, green: 0.38, blue: 0.38, alpha: 1.0)]
        ),
        "Parent-Teacher Meeting": CardStyle(
            iconName: "person.2.fill",
            gradientColors: [UIColor(red: 0.50, green: 0.75, blue: 0.92, alpha: 1.0),
                             UIColor(red: 0.32, green: 0.58, blue: 0.80, alpha: 1.0)]
        ),
        "Train Ticket Booking": CardStyle(
            iconName: "tram.fill",
            gradientColors: [UIColor(red: 0.55, green: 0.65, blue: 0.82, alpha: 1.0),
                             UIColor(red: 0.38, green: 0.48, blue: 0.72, alpha: 1.0)]
        ),
        "Emergency Call": CardStyle(
            iconName: "phone.arrow.up.right.fill",
            gradientColors: [UIColor(red: 0.92, green: 0.35, blue: 0.35, alpha: 1.0),
                             UIColor(red: 0.78, green: 0.20, blue: 0.20, alpha: 1.0)]
        ),
        "Salon Haircut": CardStyle(
            iconName: "scissors",
            gradientColors: [UIColor(red: 0.90, green: 0.72, blue: 0.85, alpha: 1.0),
                             UIColor(red: 0.75, green: 0.50, blue: 0.72, alpha: 1.0)]
        ),
        "Car Rental": CardStyle(
            iconName: "key.fill",
            gradientColors: [UIColor(red: 0.45, green: 0.78, blue: 0.70, alpha: 1.0),
                             UIColor(red: 0.28, green: 0.62, blue: 0.55, alpha: 1.0)]
        ),
        "Post Office Visit": CardStyle(
            iconName: "envelope.fill",
            gradientColors: [UIColor(red: 0.72, green: 0.62, blue: 0.50, alpha: 1.0),
                             UIColor(red: 0.58, green: 0.45, blue: 0.35, alpha: 1.0)]
        )
    ]

    static let defaultStyle = CardStyle(
        iconName: "questionmark.circle.fill",
        gradientColors: [UIColor.systemGray4, UIColor.systemGray2]
    )

    static func style(for title: String) -> CardStyle {
        return styles[title] ?? defaultStyle
    }
}
