import UIKit

enum UIHelper {
    
    // MARK: - Colors
    static let primaryColor = UIColor.systemBlue
    static let secondaryColor = UIColor.systemTeal
    
    // MARK: - Text Field Styling
    // MARK: - Text Field Styling
    static func styleTextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 12
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1.0
        
        // Use dynamic colors for borders to look good in both modes
        // Light: Gray 4, Dark: Gray 2 (lighter)
        textField.layer.borderColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray2 : UIColor.systemGray4
        }.cgColor
        
        // Background: Secondary System Background adapts automatically
        textField.backgroundColor = UIColor.secondarySystemBackground
        
        textField.textColor = UIColor.label
        
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
            )
        }
    }
    
    // MARK: - Button Styling
    
    // Primary Action (e.g. Sign In, Sign Up) - Purple
    static func stylePrimaryButton(_ button: UIButton) {
        styleButton(button,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.textOnPrimary,
                    borderColor: nil)
    }
    
    // Apple Button - Black
    static func styleAppleButton(_ button: UIButton) {
        // In Dark Mode, a black button on a black background is invisible.
        // We'll add a white border in dark mode (or always if we prefer).
        // Let's use dynamic color for the border: clear in light mode, white in dark mode.
        let borderColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.clear
        }

        styleButton(button,
                    backgroundColor: .black,
                    textColor: .white,
                    borderColor: borderColor)
    }
    
    // Google Button - White with Border
    static func styleGoogleButton(_ button: UIButton) {
        // In Dark Mode, Google button is often White with Black text, or Dark Gray with White text.
        // User screenshot had it White. Standard Google Sign In on iOS is usually White or Blue.
        // Let's stick to White background for now as it's a standard pattern, optionally adjusting for dark mode if we want a dark variant.
        // For "Polished" dark mode, typically a Light Gray or White button stands out.
        // Let's use System Background or explicitly White.
        // If we want it to be White in both modes:
        styleButton(button,
                    backgroundColor: .white,
                    textColor: .black,
                    borderColor: UIColor.systemGray4)
    }
    
    // Secondary/Hollow/Outline Button
    static func styleHollowButton(_ button: UIButton) {
        styleButton(button,
                    backgroundColor: .clear,
                    textColor: AppColors.primary,
                    borderColor: AppColors.primary)
    }
    
    // Text-only Button (e.g. Forgot Password)
    static func styleSecondaryButton(_ button: UIButton) {
        button.tintColor = AppColors.primary
        if button.configuration != nil {
             button.configuration?.baseForegroundColor = AppColors.primary
             button.configuration?.background.backgroundColor = .clear
        } else {
             button.setTitleColor(AppColors.primary, for: .normal)
             button.backgroundColor = .clear
        }
    }
    
    // Private Helper to handle Configuration vs Legacy
    private static func styleButton(_ button: UIButton, backgroundColor: UIColor, textColor: UIColor, borderColor: UIColor?) {
        button.layer.cornerRadius = 25 // Pill shape implies height/2. 50 height -> 25 radius.
        
        // Shadow (legacy layer works for shadow usually, but clipsToBounds must be off)
        // If using Configuration with filled style, masksToBounds might be true.
        // For pill shape, we can set cornerRadius on layer.
        
        if var config = button.configuration {
            config.baseBackgroundColor = backgroundColor
            config.baseForegroundColor = textColor
            config.background.cornerRadius = 25
            
            if let borderColor = borderColor {
                config.background.strokeColor = borderColor
                config.background.strokeWidth = 1.0
            } else {
                config.background.strokeWidth = 0.0
            }
            
            button.configuration = config
        } else {
            // Legacy Fallback
            button.backgroundColor = backgroundColor
            button.setTitleColor(textColor, for: .normal)
            button.layer.cornerRadius = 25
            if let borderColor = borderColor {
                button.layer.borderColor = borderColor.cgColor
                button.layer.borderWidth = 1.0
            } else {
                button.layer.borderWidth = 0.0
            }
        }
        
        // Add shadow for depth if needed (only for filled buttons)
        if backgroundColor != .clear {
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 0.1
            button.layer.masksToBounds = false
        }
    }
    
    static func styleViewController(_ viewController: UIViewController) {
        viewController.view.backgroundColor = UIColor.systemBackground
    }
    
    // MARK: - Label Styling
    static func styleLabels(in view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                // Check text to determine style
                let text = label.text?.lowercased() ?? ""
                
                if text.contains("opentone") {
                    label.textColor = AppColors.primary
                } else if text.contains("welcome") || 
                          text.contains("create") || 
                          text.contains("reset") ||
                          text.contains("select") {
                    // Title Headers
                    label.textColor = UIColor.label
                } else if text.contains("account") {
                    // "Don't have an account?" text
                    label.textColor = UIColor.label
                }
            }
            // Recursive check
            styleLabels(in: subview)
        }
    }
}
