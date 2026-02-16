import UIKit

enum UIHelper {
    
    // MARK: - Text Field Styling
    // MARK: - Text Field Styling
    static func styleTextField(_ textField: UITextField) {
        styleInputView(textField)
        
        textField.textColor = UIColor.label
        
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
            )
        }
    }
    
    /// Styles a button to look like a text field (used for pickers/selectors)
    static func styleSelectorButton(_ button: UIButton) {
        styleInputView(button)
        button.setTitleColor(UIColor.label, for: .normal)
        button.contentHorizontalAlignment = .left
        
        if #available(iOS 15.0, *) {
            var config = button.configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            button.configuration = config
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
    private static func styleInputView(_ view: UIView) {
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        
        // Use dynamic colors for borders to look good in both modes
        view.layer.borderColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray2 : UIColor.systemGray4
        }.cgColor
        
        // Background: Secondary System Background adapts automatically
        view.backgroundColor = UIColor.secondarySystemBackground
    }
    
    // MARK: - Button Styling

    // ─── Hero / Large CTA Primary Button ───
    // Full-width CTA with icon, bold text, branded purple shadow.
    // Used for: "Unleash a Topic", "Start Roleplay", "View History", etc.
    static func styleHeroPrimaryButton(
        _ button: UIButton,
        title: String,
        systemIcon: String? = nil
    ) {
        button.setTitle(title, for: .normal)
        styleLargeCTAButton(button, icon: systemIcon)
    }

    // ─── Compact Primary Button ───
    // Smaller CTA inside cards (Continue, See Progress, Settings, etc.).
    static func styleCompactPrimaryButton(
        _ button: UIButton,
        title: String? = nil,
        fontSize: CGFloat = 14
    ) {
        if let title = title {
            button.setTitle(title, for: .normal)
        }
        styleSmallCTAButton(button)
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: .bold)
    }

    // Primary Action (e.g. Sign In, Sign Up) - Purple
    // Now uses the same branded shadow as hero buttons for visual cohesion.
    static func stylePrimaryButton(_ button: UIButton) {
        button.alpha = 1.0
        button.isOpaque = true
        styleButton(button,
                    backgroundColor: AppColors.primaryButton,
                    textColor: UIColor.white,
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

    // MARK: - CTA Button Styles (Unleash / Start Roleplay theme)

    /// Large Call-to-Action button — matches the "Unleash a Topic" / "Start Roleplay" style.
    /// Adaptive purple background, white text, corner radius 27, bold purple shadow.
    /// Optionally accepts an SF Symbol name shown as a leading icon.
    static func styleLargeCTAButton(_ button: UIButton, icon: String? = nil) {
        button.configuration = nil
        button.backgroundColor = AppColors.primaryButton
        button.setTitleColor(AppColors.textOnPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 27
        button.clipsToBounds = false

        if let iconName = icon {
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            let img = UIImage(systemName: iconName, withConfiguration: config)
            button.setImage(img, for: .normal)
            button.tintColor = AppColors.textOnPrimary
            button.semanticContentAttribute = .forceLeftToRight
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        } else {
            button.setImage(nil, for: .normal)
            button.tintColor = AppColors.textOnPrimary
        }

        // Purple glow shadow
        button.layer.shadowColor = AppColors.primaryButton.cgColor
        button.layer.shadowOpacity = 0.35
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.masksToBounds = false
    }

    /// Compact CTA button used inside cards (Continue, See Progress, View History, etc.).
    /// Adaptive purple background, white text, corner radius 16, subtle branded shadow.
    static func styleSmallCTAButton(_ button: UIButton) {
        button.configuration = nil
        button.backgroundColor = AppColors.primaryButton
        button.setTitleColor(AppColors.textOnPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 16
        button.clipsToBounds = false

        // Subtle branded shadow
        button.layer.shadowColor = AppColors.primaryButton.cgColor
        button.layer.shadowOpacity = 0.22
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 8
        button.layer.masksToBounds = false
    }

    /// Circular 56×56 icon button — used for mic, speaker, close actions.
    /// Card background with card border, primary tint. Adapts to dark/light.
    static func styleCircularIconButton(_ button: UIButton, symbol: String? = nil) {
        button.layer.cornerRadius = 28
        button.backgroundColor = AppColors.cardBackground
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.cardBorder.cgColor
        button.tintColor = AppColors.primary
        button.clipsToBounds = true

        if let symbolName = symbol {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            button.setImage(UIImage(systemName: symbolName, withConfiguration: config), for: .normal)
        }
    }

    /// Refreshes circular icon button border colors on trait change.
    static func updateCircularIconButton(_ button: UIButton) {
        button.layer.borderColor = AppColors.cardBorder.cgColor
        button.backgroundColor = AppColors.cardBackground
    }

    /// Destructive action button — red tint, light red background, subtle red border.
    static func styleDestructiveButton(_ button: UIButton) {
        button.configuration = nil
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        button.setTitleColor(.systemRed, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
    }

    /// Selection-style chip/reason button — card background, visible border, primary text.
    static func styleOptionButton(_ button: UIButton) {
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor.systemGray3
                : AppColors.cardBorder
        }.cgColor
        button.backgroundColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor.tertiarySystemGroupedBackground
                : AppColors.cardBackground
        }
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.clipsToBounds = true
    }

    // Private Helper to handle Configuration vs Legacy
    private static func styleButton(_ button: UIButton, backgroundColor: UIColor, textColor: UIColor, borderColor: UIColor?) {
        button.layer.cornerRadius = 25
        button.clipsToBounds = false
        
        // Ensure button has proper appearance
        button.alpha = 1.0
        button.isOpaque = false
        
        // Get or create configuration
        var config = button.configuration ?? UIButton.Configuration.filled()
        
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = textColor
        config.background.cornerRadius = 25
        config.titleAlignment = .center
        
        // Ensure text is properly styled in configuration
        var titleAttr = AttributeContainer()
        titleAttr.foregroundColor = textColor
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)
        
        if let borderColor = borderColor {
            config.background.strokeColor = borderColor
            config.background.strokeWidth = 1.0
        } else {
            config.background.strokeWidth = 0.0
        }
        
        // Apply the configuration
        button.configuration = config
        
        // Force explicit color settings on all possible text rendering paths
        button.tintColor = textColor
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor, for: .highlighted)
        button.setTitleColor(textColor, for: .disabled)
        button.setTitleColor(textColor, for: .focused)
        button.setTitleColor(textColor, for: .application)
        button.setTitleColor(textColor, for: .reserved)
        button.setTitleColor(textColor, for: .selected)
        
        // Update title label appearance
        button.titleLabel?.textColor = textColor
        button.titleLabel?.font = button.titleLabel?.font ?? .systemFont(ofSize: 17)
        
        // Force configuration update
        if #available(iOS 15.1, *) {
            button.setNeedsUpdateConfiguration()
        }
        
        // Add branded shadow for depth on filled buttons
        if backgroundColor != .clear {
            button.layer.shadowColor = AppColors.primaryButton.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
            button.layer.shadowRadius = 10
            button.layer.shadowOpacity = 0.28
            button.layer.masksToBounds = false
        }
    }
    
    // MARK: - Button State Management
    
    /// Centralized method to set button enabled/disabled state with consistent visual feedback
    /// - Parameters:
    ///   - button: The button to update
    ///   - enabled: Whether the button should be enabled
    static func setButtonState(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : 0.7
    }
    
    static func styleViewController(_ viewController: UIViewController) {
        viewController.view.backgroundColor = AppColors.screenBackground
    }
    
    // MARK: - Card Styling
    static func styleCardView(_ view: UIView) {
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.cardBorder.cgColor
        
        // Shadow configuration
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.08
        view.layer.masksToBounds = false
    }
    
    // MARK: - Validation Styling
    
    // MARK: - Validation Styling
    
    // Custom Label to store original constraint for restoration
    class ErrorLabel: UILabel {
        weak var impactedConstraint: NSLayoutConstraint?
        var originalConstant: CGFloat = 0
    }
    
    static func showError(message: String, on textField: UITextField, in view: UIView, nextView: UIView? = nil) {
        // 1. Change Border Color
        textField.layer.borderColor = UIColor.systemRed.cgColor
        
        let tag = textField.hashValue // Simple unique ID binding
        
        // 2. Check if error exists
        // If inside StackView, check arrangedSubviews or subviews
        if let existingLabel = view.viewWithTag(tag) as? ErrorLabel {
            existingLabel.text = message
            existingLabel.isHidden = false
            return
        }
        
        // Check if textField is in a StackView
        if let stackView = textField.superview as? UIStackView {
            // Stack View Logic
            
            // Check if we already have an error label in the stack info
            if let existingLabel = stackView.viewWithTag(tag) as? ErrorLabel {
                existingLabel.text = message
                
                // Animate showing
                if existingLabel.isHidden {
                    UIView.animate(withDuration: 0.3) {
                        existingLabel.isHidden = false
                        stackView.layoutIfNeeded()
                    }
                }
                return
            }
            
            // Create new label
            let label = ErrorLabel()
            label.tag = tag
            label.textColor = .systemRed
            label.font = .systemFont(ofSize: 12, weight: .regular)
            label.numberOfLines = 0
            label.text = message
            
            // Initial state for animation
            label.isHidden = true
            label.alpha = 0
            
            // Insert into StackView
            // Find index of textField
            if let index = stackView.arrangedSubviews.firstIndex(of: textField) {
                stackView.insertArrangedSubview(label, at: index + 1)
                
                // Animate
                UIView.animate(withDuration: 0.3) {
                    label.isHidden = false
                    label.alpha = 1
                    stackView.layoutIfNeeded()
                }
            }
            
        } else {
            // 3. Standard Layout Logic (Non-StackView)
            
            let label = ErrorLabel()
            label.tag = tag
            label.textColor = .systemRed
            label.font = .systemFont(ofSize: 12, weight: .regular)
            label.numberOfLines = 0
            label.text = message
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // 4. Add to view hierarchy (using textField's superview)
            guard let superview = textField.superview else { return }
            superview.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
                label.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 4),
                label.trailingAnchor.constraint(equalTo: textField.trailingAnchor)
            ])
            
            // 5. Adjust Spacing of Next View if provided
            if let nextView = nextView {
                // Search for constraint in both superview and the main view (passed as 'view' parameter)
                let viewsToSearch = [superview, view].compactMap { $0 }
                
                var foundConstraint: NSLayoutConstraint?
                for searchView in viewsToSearch {
                    if let constraint = searchView.constraints.first(where: {
                        ($0.firstItem === nextView && $0.firstAttribute == .top && $0.secondItem === textField && $0.secondAttribute == .bottom) ||
                        ($0.secondItem === nextView && $0.secondAttribute == .top && $0.firstItem === textField && $0.firstAttribute == .bottom)
                    }) {
                        foundConstraint = constraint
                        break
                    }
                }
                
                if let constraint = foundConstraint {
                    // Store original
                    label.impactedConstraint = constraint
                    label.originalConstant = constraint.constant
                    
                    // Increase spacing to accommodate error label (approx 30pt for text + padding)
                    constraint.constant += 30
                    
                    // Animate layout changes
                    UIView.animate(withDuration: 0.2) {
                        view.layoutIfNeeded()
                    }
                }
            }
            
            // Optional: Animate
            label.alpha = 0
            UIView.animate(withDuration: 0.2) {
                label.alpha = 1
            }
        }
    }
    
    static func clearError(on textField: UITextField) {
        // 1. Reset Border
        textField.layer.borderColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor.systemGray2 : UIColor.systemGray4
        }.cgColor
        
        let tag = textField.hashValue
        
        // 2. Handle StackView or Standard Layout
        if let stackView = textField.superview as? UIStackView {
            // Stack View Logic
            if let label = stackView.viewWithTag(tag) as? ErrorLabel {
                
                UIView.animate(withDuration: 0.3, animations: {
                    label.isHidden = true
                    label.alpha = 0
                    stackView.layoutIfNeeded()
                }) { _ in
                    stackView.removeArrangedSubview(label)
                    label.removeFromSuperview()
                }
            }
            
        } else {
            // Standard Layout Logic
            if let superview = textField.superview, let label = superview.viewWithTag(tag) as? ErrorLabel {
                
                // Restore Constraint
                if let constraint = label.impactedConstraint {
                    constraint.constant = label.originalConstant
                    UIView.animate(withDuration: 0.2) {
                        superview.layoutIfNeeded()
                    }
                }
                
                UIView.animate(withDuration: 0.1, animations: {
                    label.alpha = 0
                }) { _ in
                    label.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: - Label Styling
    static func styleLabels(in view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                // Ignore error labels (red)
                if label.textColor == .systemRed { continue }
                
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
