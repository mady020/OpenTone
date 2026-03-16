import UIKit
import AuthenticationServices

final class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false

    private var loginButton: UIButton?
    private var appleSignInButton: ASAuthorizationAppleIDButton?
    
    private var passwordToggleButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        // Prevent iOS Password AutoFill (which causes yellow background tint)
        // Using an empty textContentType avoids AutoFill without breaking caps lock
        passwordField.textContentType = .init(rawValue: "")
        passwordField.passwordRules = UITextInputPasswordRules(descriptor: "")
        addIconsToTextFields()
        addPasswordToggle()
        setupUI()
        setupValidation()
    }

    private func setupUI() {
        UIHelper.styleViewController(self)
        UIHelper.styleTextField(emailField)
        UIHelper.styleTextField(passwordField)
        UIHelper.styleLabels(in: view)
        
        // Apply styling to buttons found in view hierarchy
        findButtons(in: view).forEach { button in
            // Identify buttons by connection actions or title text
            let actions = button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []
            let title = button.title(for: .normal)?.lowercased() ?? 
                        button.configuration?.title?.lowercased() ?? ""
            
            if actions.contains("signinButtonTapped:") {
                UIHelper.stylePrimaryButton(button)
                self.loginButton = button
            } else if actions.contains("googleButtonTapped:") || title.contains("google") {
                UIHelper.styleGoogleButton(button)
            } else if title.contains("apple") {
                replaceWithAppleSignInButton(placeholder: button)
            } else if title.contains("forgot") {
                UIHelper.styleSecondaryButton(button)
            } else {
                // Default fallback if any other buttons appear
                UIHelper.styleSecondaryButton(button)
            }
        }
        
        validateInputs()
    }
    
    private func setupValidation() {
        emailField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    @objc private func textDidChange(_ sender: UITextField) {
        validateInputs()
    }
    
    private func validateInputs() {
        var isValid = true
        
        // Email Validation
        if let error = AuthValidator.validateEmail(emailField.text) {
             if let text = emailField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: emailField, in: view, nextView: passwordField)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: emailField)
        }
        
        // Password Validation
        if let error = AuthValidator.validatePassword(passwordField.text) {
             if let text = passwordField.text, !text.isEmpty {
                 // Push login button
                 UIHelper.showError(message: error, on: passwordField, in: view, nextView: loginButton)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: passwordField)
        }
        
        // Update Button State
        if let button = loginButton {
            UIHelper.setButtonState(button, enabled: isValid)
        }
    }
    
    private func findButtons(in view: UIView) -> [UIButton] {
        var buttons: [UIButton] = []
        for subview in view.subviews {
            if let button = subview as? UIButton {
                buttons.append(button)
            }
            buttons.append(contentsOf: findButtons(in: subview))
        }
        return buttons
    }

    @IBAction func signinButtonTapped(_ sender: Any) {
        handleLogin()
    }
    
    @IBAction func googleButtonTapped(_ sender: Any) {
        handleQuickSignIn()
    }

    @IBAction func appleButtonTapped(_ sender: Any) {
        showAppleSignInUnavailableAlert()
    }

    private func showAppleSignInUnavailableAlert() {
        let alert = UIAlertController(
            title: "Apple Sign-In Unavailable",
            message: "This feature is not working right now. Please use email or Google sign-in.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    
    
    private func handleQuickSignIn() {
        let alert = UIAlertController(
            title: "Not Available",
            message: "Quick sign-in is disabled. Please use your email and password.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func handleLogin() {
        // Double check validation
        guard
            AuthValidator.validateEmail(emailField.text) == nil,
            AuthValidator.validatePassword(passwordField.text) == nil,
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            return
        }

        Task { @MainActor in
            guard let user = await UserDataModel.shared.authenticate(email: email, password: password) else {
                let alert = UIAlertController(title: "Login Failed", message: "Invalid email or password", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }

            SessionManager.shared.login(user: user)
            routeAfterLogin()
        }
    }

    private func routeAfterLogin() {
        let destination = OnboardingDestinationResolver.destination(for: SessionManager.shared.currentUser)
        switch destination {
        case .dashboard:
            goToDashboard()
        case .userInfo:
            goToOnboardingScreen("UserInfoScreen")
        case .confidence:
            goToOnboardingScreen("ConfidenceScreen")
        case .interestsIntro:
            goToOnboardingScreen("InterestsIntro")
        case .commitment:
            goToOnboardingScreen("CommitmentScreen")
        case .login:
            break
        }
    }

    private func goToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(
            withIdentifier: "MainTabBarController"
        )

        tabBarVC.modalPresentationStyle = .fullScreen
        tabBarVC.modalTransitionStyle = .crossDissolve

        view.window?.rootViewController = tabBarVC
        view.window?.makeKeyAndVisible()
    }

    private func goToOnboardingScreen(_ identifier: String) {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let userInfoVC = storyboard.instantiateViewController(
            withIdentifier: identifier
        )

        let nav = UINavigationController(rootViewController: userInfoVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve

        view.window?.rootViewController = nav
        view.window?.makeKeyAndVisible()
    }

    private func addIconsToTextFields() {

        emailField.leftView = makeIconView(systemName: "envelope.fill")
        emailField.leftViewMode = .always

        passwordField.leftView = makeIconView(systemName: "lock.fill")
        passwordField.leftViewMode = .always
    }

    // Use a fixed symbol configuration so every SF Symbol is rendered the same size
    private func makeIconView(systemName: String) -> UIView {
        // Choose the pointSize you want for all icons (change 18 to taste)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: systemName, withConfiguration: symbolConfig)

        let iconView = UIImageView(image: image)
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        // Container guarantees a consistent leftView width and center alignment
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        // Fixed container size (change width/height to match your design)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 44),
            container.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }

    // MARK: - Apple Sign In

    private func replaceWithAppleSignInButton(placeholder: UIButton) {
        guard let superview = placeholder.superview else { return }

        let style: ASAuthorizationAppleIDButton.Style = traitCollection.userInterfaceStyle == .dark ? .white : .black
        let appleButton = ASAuthorizationAppleIDButton(type: .continue, style: style)
        appleButton.cornerRadius = 25
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.addTarget(self, action: #selector(appleButtonTapped(_:)), for: .touchUpInside)

        if let stackView = superview as? UIStackView,
           let index = stackView.arrangedSubviews.firstIndex(of: placeholder) {
            stackView.insertArrangedSubview(appleButton, at: index)
            placeholder.removeFromSuperview()
            appleButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        } else {
            superview.addSubview(appleButton)
            NSLayoutConstraint.activate([
                appleButton.leadingAnchor.constraint(equalTo: placeholder.leadingAnchor),
                appleButton.trailingAnchor.constraint(equalTo: placeholder.trailingAnchor),
                appleButton.topAnchor.constraint(equalTo: placeholder.topAnchor),
                appleButton.heightAnchor.constraint(equalToConstant: 50)
            ])
            placeholder.removeFromSuperview()
        }

        self.appleSignInButton = appleButton
    }

    // Prefer a UIButton for the eye toggle so the tap target is predictable
    private func addPasswordToggle() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let eyeImage = UIImage(systemName: "eye.slash.fill", withConfiguration: symbolConfig)

        // Use .custom to avoid UIButton adding system padding/scaling
        let button = UIButton(type: .custom)
        button.setImage(eyeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.contentEdgeInsets = .zero
        button.imageEdgeInsets = .zero
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        button.accessibilityLabel = "Toggle password visibility"

        // Keep a reference so we can update the image reliably later
        self.passwordToggleButton = button

        // Container keeps rightView width consistent and preserves a 44pt touch target
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 44),
            container.heightAnchor.constraint(equalToConstant: 44),

            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 20),
            button.heightAnchor.constraint(equalToConstant: 20)
        ])

        passwordField.rightView = container
        passwordField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()

        // Save current text — toggling isSecureTextEntry can clear it on some iOS versions
        let existingText = passwordField.text

        passwordField.isSecureTextEntry = !isPasswordVisible

        // Restore the text (iOS may clear it during the secure ↔ plain switch)
        passwordField.text = existingText

        // Move cursor to end so the user can keep typing naturally
        if passwordField.isFirstResponder {
            let endPosition = passwordField.endOfDocument
            passwordField.selectedTextRange = passwordField.textRange(from: endPosition, to: endPosition)
        }

        // Update button image with same symbol configuration used elsewhere
        let symbol = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let img = UIImage(systemName: symbol, withConfiguration: symbolConfig)
        passwordToggleButton?.setImage(img, for: .normal)
    }
}

