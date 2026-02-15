import UIKit

struct AppColors {
    static let screenBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .systemBackground : UIColor(hex: "#F4F5F7")
    }
    
    static let cardBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : UIColor(hex: "#FFFFFF")
    }
    
    // Primary button color - consistent purple across both modes
    static let primary = UIColor(hex: "#5B3CC4") // Brand color
    
    /// A lighter tint of the primary brand color — used for ring tracks, chip backgrounds, badges.
    static let primaryLight = UIColor { trait in
        return trait.userInterfaceStyle == .dark
            ? UIColor(hex: "#5B3CC4").withAlphaComponent(0.25)
            : UIColor(red: 0.949, green: 0.933, blue: 1.0, alpha: 1.0) // #F2EDFF
    }
    
    /// Ring track background that adapts to dark/light mode.
    static let ringTrack = UIColor { trait in
        return trait.userInterfaceStyle == .dark
            ? UIColor.systemGray5
            : UIColor(red: 0.92, green: 0.87, blue: 1.0, alpha: 1.0) // light purple
    }
    
    /// Text secondary — used for subtitles, captions, and secondary labels.
    static let textSecondary = UIColor.secondaryLabel
    
    static let textPrimary = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .label : UIColor(hex: "#1A1A1A")
    }
    
    // Text on primary (buttons, etc) - always white for contrast
    static let textOnPrimary = UIColor.white
    
    static let cardBorder = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .separator : UIColor(hex: "#E6E3EE")
    }

    static let success = UIColor.systemGreen
    static let error = UIColor.systemRed
    
    /// Streak badge background — warm amber in light mode, dark amber in dark mode.
    static let streakBadgeBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.25, blue: 0.05, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
    }
    
    /// Streak badge text color.
    static let streakBadgeText = UIColor { trait in
        return trait.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1.0)
            : UIColor(red: 0.55, green: 0.35, blue: 0.0, alpha: 1.0)
    }
}
