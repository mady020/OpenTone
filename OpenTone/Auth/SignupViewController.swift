import UIKit
import AuthenticationServices

final class SignupViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false

    private var signupButton: UIButton?
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure text fields re-evaluate their left/right views after layout passes
        nameField.layoutIfNeeded()
        emailField.layoutIfNeeded()
        passwordField.layoutIfNeeded()
    }

    // MARK: - Icon + Password Toggle Setup

    private func addIconsToTextFields() {
        nameField.leftView = makeIconView(systemName: "person.fill")
        nameField.leftViewMode = .always

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

    // MARK: - Original UI + Validation Methods (unchanged logic)

    private func setupUI() {
        UIHelper.styleViewController(self)
        UIHelper.styleTextField(nameField)
        UIHelper.styleTextField(emailField)
        UIHelper.styleTextField(passwordField)
        UIHelper.styleLabels(in: view)

        findButtons(in: view).forEach { button in
            let actions = button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []
            let title = button.title(for: .normal)?.lowercased() ??
                        button.configuration?.title?.lowercased() ?? ""

            if actions.contains("signupButtonTapped:") {
                UIHelper.stylePrimaryButton(button)
                self.signupButton = button
            } else if actions.contains("googleButtonTapped:") || title.contains("google") {
                UIHelper.styleGoogleButton(button)
            } else if title.contains("apple") {
                replaceWithAppleSignInButton(placeholder: button)
            } else if actions.contains("signinButtonTapped:") || title.contains("sign in") {
                UIHelper.styleSecondaryButton(button)
            }
        }

        // Initial state
        validateInputs()
    }

    private func setupValidation() {
        nameField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        emailField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    @objc private func textDidChange(_ sender: UITextField) {
        validateInputs()
    }

    private func validateInputs() {
        var isValid = true

        // Name Validation
        if let error = AuthValidator.validateName(nameField.text) {
            // Only show error if user has started typing
            if let text = nameField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: nameField, in: view, nextView: emailField)
            }
            isValid = false
        } else {
            UIHelper.clearError(on: nameField)
        }

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
                 UIHelper.showError(message: error, on: passwordField, in: view, nextView: signupButton)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: passwordField)
        }

        // Update Button State
        if let button = signupButton {
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

    @IBAction func signupButtonTapped(_ sender: UIButton) {
        handleSignup()
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
            message: "This feature is not working right now. Please use email.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func handleQuickSignIn() {
        let alert = UIAlertController(
            title: "Not Available",
            message: "Quick sign-in is disabled. Please create an account with email and password.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func signinButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    private func handleSignup() {
        // Double check validation
        guard
            AuthValidator.validateName(nameField.text) == nil,
            AuthValidator.validateEmail(emailField.text) == nil,
            AuthValidator.validatePassword(passwordField.text) == nil,
            let name = nameField.text,
            let email = emailField.text,
            let password = passwordField.text
        else {
            return
        }

        Task { @MainActor in
            let (user, error) = await UserDataModel.shared.registerWithSupabaseAuthAndError(
                name: name,
                email: email,
                password: password
            )
            
            // Check if email confirmation is pending
            if let error = error, error == "EMAIL_CONFIRMATION_PENDING" {
                showEmailConfirmationAlert(email: email)
                return
            }
            
            guard let user = user else {
                showErrorAlert(message: error ?? "Signup failed. Please try again.")
                return
            }

            SessionManager.shared.login(user: user)
            routeAfterAuth()
        }
    }

    private func showEmailConfirmationAlert(email: String) {
        let alert = UIAlertController(
            title: "Confirm Your Email",
            message: "A confirmation email has been sent to \(email). Please check your email and click the confirmation link to complete your signup.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "I've Confirmed My Email", style: .default) { [weak self] _ in
                // After user confirms, try to log in
                self?.attemptLoginAfterConfirmation(email: email)
            }
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                // Clear the signup form
                self?.clearSignupForm()
            }
        )

        present(alert, animated: true)
    }

    private func attemptLoginAfterConfirmation(email: String) {
        guard let password = passwordField.text else { return }
        
        Task { @MainActor in
            guard let user = await UserDataModel.shared.authenticate(email: email, password: password) else {
                showErrorAlert(message: "Could not log in. Please try signing in manually.")
                return
            }

            SessionManager.shared.login(user: user)
            routeAfterAuth()
        }
    }

    private func routeAfterAuth() {
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

    private func clearSignupForm() {
        nameField.text = ""
        emailField.text = ""
        passwordField.text = ""
        validateInputs()
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Signup Failed",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }

    private func showUserExistsAlert() {
        let alert = UIAlertController(
            title: "User Already Exists",
            message: "An account with this email already exists.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Login", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )

        present(alert, animated: true)
    }

    private func goToOnboardingScreen(_ identifier: String) {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let userInfoVC = storyboard.instantiateViewController(
            withIdentifier: identifier
        )

        let nav = UINavigationController(rootViewController: userInfoVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve

        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = nav
            }, completion: nil)
            window.makeKeyAndVisible()
        }
    }

    private func goToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(
            withIdentifier: "MainTabBarController"
        )

        tabBarVC.modalPresentationStyle = .fullScreen
        tabBarVC.modalTransitionStyle = .crossDissolve

        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = tabBarVC
            }, completion: nil)
            window.makeKeyAndVisible()
        }
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
}

