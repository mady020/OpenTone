import UIKit

struct AppColors {
    static let screenBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .systemBackground : UIColor(hex: "#F4F5F7")
    }
    
    static let cardBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : UIColor(hex: "#FBF8FF")
    }
    
    static let primary = UIColor(hex: "#5B3CC4") // Keep brand color same, user liked it
    
    static let textPrimary = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .label : UIColor(hex: "#333333")
    }
    
    static let textOnPrimary = UIColor.white
    
    static let cardBorder = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .separator : UIColor(hex: "#E6E3EE")
    }
}
