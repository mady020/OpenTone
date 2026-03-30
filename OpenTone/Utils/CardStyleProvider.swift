import UIKit

/// Shared card style data used by the Roleplays tab, Dashboard, and Detail screen.
struct CardStyle {
    let iconName: String
    let gradientColors: [UIColor]
}

struct CardStyleProvider {

    static let styles: [String: CardStyle] = [
        "Job Interview": CardStyle(
            iconName: "briefcase.fill",
            gradientColors: [UIColor(red: 0.72, green: 0.78, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.48, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Team Intro": CardStyle(
            iconName: "person.2.fill",
            gradientColors: [UIColor(red: 0.58, green: 0.86, blue: 0.90, alpha: 1.0),
                             UIColor(red: 0.35, green: 0.69, blue: 0.78, alpha: 1.0)]
        ),
        "Project Update": CardStyle(
            iconName: "chart.bar.xaxis",
            gradientColors: [UIColor(red: 0.67, green: 0.82, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.44, green: 0.62, blue: 0.86, alpha: 1.0)]
        ),
        "Scope Clarify": CardStyle(
            iconName: "questionmark.bubble.fill",
            gradientColors: [UIColor(red: 0.84, green: 0.79, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.63, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Design Review": CardStyle(
            iconName: "person.2.wave.2.fill",
            gradientColors: [UIColor(red: 0.96, green: 0.75, blue: 0.70, alpha: 1.0),
                             UIColor(red: 0.84, green: 0.52, blue: 0.48, alpha: 1.0)]
        ),
        "Manager Feedback": CardStyle(
            iconName: "person.crop.circle.badge.exclamationmark",
            gradientColors: [UIColor(red: 0.97, green: 0.82, blue: 0.63, alpha: 1.0),
                             UIColor(red: 0.87, green: 0.63, blue: 0.34, alpha: 1.0)]
        ),
        "Client Kickoff": CardStyle(
            iconName: "person.3.sequence.fill",
            gradientColors: [UIColor(red: 0.68, green: 0.83, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.45, green: 0.64, blue: 0.84, alpha: 1.0)]
        ),
        "Negotiate Scope": CardStyle(
            iconName: "scale.3d",
            gradientColors: [UIColor(red: 0.89, green: 0.86, blue: 0.64, alpha: 1.0),
                             UIColor(red: 0.74, green: 0.66, blue: 0.35, alpha: 1.0)]
        ),
        "Executive Pitch": CardStyle(
            iconName: "rectangle.on.rectangle.angled.fill",
            gradientColors: [UIColor(red: 0.62, green: 0.80, blue: 0.97, alpha: 1.0),
                             UIColor(red: 0.36, green: 0.58, blue: 0.85, alpha: 1.0)]
        ),
        "Incident Comms": CardStyle(
            iconName: "bolt.horizontal.fill",
            gradientColors: [UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1.0),
                             UIColor(red: 0.89, green: 0.45, blue: 0.24, alpha: 1.0)]
        ),
        "Group Project": CardStyle(
            iconName: "person.3.fill",
            gradientColors: [UIColor(red: 0.90, green: 0.74, blue: 0.56, alpha: 1.0),
                             UIColor(red: 0.80, green: 0.54, blue: 0.28, alpha: 1.0)]
        ),
        "Class Clarify": CardStyle(
            iconName: "questionmark.circle.fill",
            gradientColors: [UIColor(red: 0.77, green: 0.86, blue: 1.00, alpha: 1.0),
                             UIColor(red: 0.55, green: 0.69, blue: 0.88, alpha: 1.0)]
        ),
        "Making Plans": CardStyle(
            iconName: "calendar.badge.clock",
            gradientColors: [UIColor(red: 0.78, green: 0.91, blue: 0.76, alpha: 1.0),
                             UIColor(red: 0.52, green: 0.75, blue: 0.49, alpha: 1.0)]
        ),
        "Ask Extension": CardStyle(
            iconName: "clock.arrow.circlepath",
            gradientColors: [UIColor(red: 0.84, green: 0.83, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.63, green: 0.59, blue: 0.83, alpha: 1.0)]
        ),
        "Fix Conflict": CardStyle(
            iconName: "person.2.fill",
            gradientColors: [UIColor(red: 0.95, green: 0.75, blue: 0.77, alpha: 1.0),
                             UIColor(red: 0.82, green: 0.54, blue: 0.58, alpha: 1.0)]
        ),
        "App Support": CardStyle(
            iconName: "headphones",
            gradientColors: [UIColor(red: 0.79, green: 0.82, blue: 0.96, alpha: 1.0),
                             UIColor(red: 0.55, green: 0.61, blue: 0.86, alpha: 1.0)]
        ),
        "Store Return": CardStyle(
            iconName: "arrow.uturn.backward.circle.fill",
            gradientColors: [UIColor(red: 0.97, green: 0.83, blue: 0.62, alpha: 1.0),
                             UIColor(red: 0.86, green: 0.65, blue: 0.32, alpha: 1.0)]
        ),
        "Networking": CardStyle(
            iconName: "bubble.left.and.bubble.right.fill",
            gradientColors: [UIColor(red: 0.90, green: 0.78, blue: 0.97, alpha: 1.0),
                             UIColor(red: 0.72, green: 0.56, blue: 0.86, alpha: 1.0)]
        ),
        "Giving Advice": CardStyle(
            iconName: "heart.text.square.fill",
            gradientColors: [UIColor(red: 0.98, green: 0.74, blue: 0.74, alpha: 1.0),
                             UIColor(red: 0.86, green: 0.50, blue: 0.53, alpha: 1.0)]
        ),
        "Fix Confusion": CardStyle(
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
