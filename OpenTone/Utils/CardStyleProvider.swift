import UIKit

/// Shared card style data used by the Roleplays tab, Dashboard, and Detail screen.
struct CardStyle {
    let iconName: String
    let gradientColors: [UIColor]
}

struct CardStyleProvider {

    static let styles: [String: CardStyle] = [
        "Behavioral Job Interview": CardStyle(
            iconName: "briefcase.fill",
            gradientColors: [UIColor(red: 0.72, green: 0.78, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.48, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Team Introduction on Day One": CardStyle(
            iconName: "person.2.fill",
            gradientColors: [UIColor(red: 0.58, green: 0.86, blue: 0.90, alpha: 1.0),
                             UIColor(red: 0.35, green: 0.69, blue: 0.78, alpha: 1.0)]
        ),
        "Weekly Project Status Update": CardStyle(
            iconName: "chart.bar.xaxis",
            gradientColors: [UIColor(red: 0.67, green: 0.82, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.44, green: 0.62, blue: 0.86, alpha: 1.0)]
        ),
        "Clarifying Requirements with Product Manager": CardStyle(
            iconName: "questionmark.bubble.fill",
            gradientColors: [UIColor(red: 0.84, green: 0.79, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.63, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Disagreeing Professionally in a Design Review": CardStyle(
            iconName: "person.2.wave.2.fill",
            gradientColors: [UIColor(red: 0.96, green: 0.75, blue: 0.70, alpha: 1.0),
                             UIColor(red: 0.84, green: 0.52, blue: 0.48, alpha: 1.0)]
        ),
        "Receiving Tough Feedback from Your Manager": CardStyle(
            iconName: "person.crop.circle.badge.exclamationmark",
            gradientColors: [UIColor(red: 0.97, green: 0.82, blue: 0.63, alpha: 1.0),
                             UIColor(red: 0.87, green: 0.63, blue: 0.34, alpha: 1.0)]
        ),
        "Client Kickoff Meeting": CardStyle(
            iconName: "person.3.sequence.fill",
            gradientColors: [UIColor(red: 0.68, green: 0.83, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.45, green: 0.64, blue: 0.84, alpha: 1.0)]
        ),
        "Negotiating Scope and Timeline": CardStyle(
            iconName: "scale.3d",
            gradientColors: [UIColor(red: 0.89, green: 0.86, blue: 0.64, alpha: 1.0),
                             UIColor(red: 0.74, green: 0.66, blue: 0.35, alpha: 1.0)]
        ),
        "Executive Presentation with Q&A": CardStyle(
            iconName: "rectangle.on.rectangle.angled.fill",
            gradientColors: [UIColor(red: 0.62, green: 0.80, blue: 0.97, alpha: 1.0),
                             UIColor(red: 0.36, green: 0.58, blue: 0.85, alpha: 1.0)]
        ),
        "High-Pressure Incident Communication": CardStyle(
            iconName: "bolt.horizontal.fill",
            gradientColors: [UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1.0),
                             UIColor(red: 0.89, green: 0.45, blue: 0.24, alpha: 1.0)]
        ),
        "Campus Group Project Kickoff": CardStyle(
            iconName: "person.3.fill",
            gradientColors: [UIColor(red: 0.90, green: 0.74, blue: 0.56, alpha: 1.0),
                             UIColor(red: 0.80, green: 0.54, blue: 0.28, alpha: 1.0)]
        ),
        "Asking a Professor for Clarification": CardStyle(
            iconName: "questionmark.circle.fill",
            gradientColors: [UIColor(red: 0.77, green: 0.86, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.55, green: 0.69, blue: 0.88, alpha: 1.0)]
        ),
        "Making Plans and Rescheduling Politely": CardStyle(
            iconName: "calendar.badge.clock",
            gradientColors: [UIColor(red: 0.78, green: 0.91, blue: 0.76, alpha: 1.0),
                             UIColor(red: 0.52, green: 0.75, blue: 0.49, alpha: 1.0)]
        ),
        "Requesting an Assignment Extension": CardStyle(
            iconName: "clock.arrow.circlepath",
            gradientColors: [UIColor(red: 0.84, green: 0.83, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.63, green: 0.59, blue: 0.83, alpha: 1.0)]
        ),
        "Roommate Conflict About Shared Responsibilities": CardStyle(
            iconName: "person.2.fill",
            gradientColors: [UIColor(red: 0.95, green: 0.75, blue: 0.77, alpha: 1.0),
                             UIColor(red: 0.82, green: 0.54, blue: 0.58, alpha: 1.0)]
        ),
        "Customer Support for a Broken App Subscription": CardStyle(
            iconName: "headphones",
            gradientColors: [UIColor(red: 0.79, green: 0.82, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.55, green: 0.61, blue: 0.86, alpha: 1.0)]
        ),
        "Returning a Faulty Purchase": CardStyle(
            iconName: "arrow.uturn.backward.circle.fill",
            gradientColors: [UIColor(red: 0.97, green: 0.83, blue: 0.62, alpha: 1.0),
                             UIColor(red: 0.86, green: 0.65, blue: 0.32, alpha: 1.0)]
        ),
        "First-Time Networking at a Student Event": CardStyle(
            iconName: "bubble.left.and.bubble.right.fill",
            gradientColors: [UIColor(red: 0.90, green: 0.78, blue: 0.97, alpha: 1.0),
                             UIColor(red: 0.72, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Giving Advice to a Stressed Friend": CardStyle(
            iconName: "heart.text.square.fill",
            gradientColors: [UIColor(red: 0.98, green: 0.74, blue: 0.74, alpha: 1.0),
                             UIColor(red: 0.86, green: 0.50, blue: 0.53, alpha: 1.0)]
        ),
        "Fixing Miscommunication in a Group Chat": CardStyle(
            iconName: "ellipsis.bubble.fill",
            gradientColors: [UIColor(red: 0.88, green: 0.84, blue: 0.98, alpha: 1.0),
                             UIColor(red: 0.68, green: 0.60, blue: 0.85, alpha: 1.0)]
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
