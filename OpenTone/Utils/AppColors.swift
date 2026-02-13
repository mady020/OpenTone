import UIKit

struct AppColors {
    static let screenBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .systemBackground : UIColor(hex: "#F4F5F7")
    }
    
    static let cardBackground = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : UIColor(hex: "#FFFFFF")
    }
    
    static let primary = UIColor(hex: "#5B3CC4") // Brand color
    
    static let textPrimary = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .label : UIColor(hex: "#1A1A1A")
    }
    
    static let textOnPrimary = UIColor.white
    
    static let cardBorder = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? .separator : UIColor(hex: "#E6E3EE")
    }

    static let success = UIColor.systemGreen
    static let error = UIColor.systemRed
}
