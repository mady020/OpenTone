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
        
        findButtons(in: view).forEach { button in
            let actions = button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []
            let title = button.title(for: .normal)?.lowercased() ?? 
                        button.configuration?.title?.lowercased() ?? ""
            
            if actions.contains("signinButtonTapped:") {
                UIHelper.stylePrimaryButton(button)
                self.loginButton = button
            } else if title.contains("apple") {
                replaceWithAppleSignInButton(placeholder: button)
            } else if title.contains("forgot") {
                UIHelper.styleSecondaryButton(button)
            } else {
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
        
        if let error = AuthValidator.validateEmail(emailField.text) {
             if let text = emailField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: emailField, in: view, nextView: passwordField)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: emailField)
        }
        
        if let error = AuthValidator.validatePassword(passwordField.text) {
             if let text = passwordField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: passwordField, in: view, nextView: loginButton)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: passwordField)
        }
        
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

    
    @IBAction func appleButtonTapped(_ sender: Any) {
    }

    
    
    private func handleQuickSignIn() {
        guard let sampleUser = UserDataModel.shared.getSampleUserForQuickSignIn() else {
            let alert = UIAlertController(title: "Error", message: "Could not load sample user", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        SessionManager.shared.login(user: sampleUser)
        SampleDataSeeder.shared.seedIfNeeded()
        goToDashboard()
    }

    private func handleLogin() {
        guard
            AuthValidator.validateEmail(emailField.text) == nil,
            AuthValidator.validatePassword(passwordField.text) == nil,
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            return
        }

        guard let user = UserDataModel.shared.authenticate(
            email: email,
            password: password
        ) else {
            let alert = UIAlertController(title: "Login Failed", message: "Invalid email or password", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        SessionManager.shared.login(user: user)
        routeAfterLogin()
    }

    private func routeAfterLogin() {
        guard let user = SessionManager.shared.currentUser else { return }

        if user.confidenceLevel == nil {
            goToUserInfo()
        } else {
            goToDashboard()
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

    private func goToUserInfo() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let userInfoVC = storyboard.instantiateViewController(
            withIdentifier: "UserInfoScreen"
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

    private func makeIconView(systemName: String) -> UIView {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: systemName, withConfiguration: symbolConfig)

        let iconView = UIImageView(image: image)
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

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

    private func addPasswordToggle() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let eyeImage = UIImage(systemName: "eye.slash.fill", withConfiguration: symbolConfig)

        let button = UIButton(type: .custom)
        button.setImage(eyeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.contentEdgeInsets = .zero
        button.imageEdgeInsets = .zero
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        button.accessibilityLabel = "Toggle password visibility"

        self.passwordToggleButton = button

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

        let wasFirstResponder = passwordField.isFirstResponder
        if wasFirstResponder { passwordField.resignFirstResponder() }

        let text = passwordField.text
        passwordField.isSecureTextEntry = !isPasswordVisible
        passwordField.text = text

        if wasFirstResponder { passwordField.becomeFirstResponder() }
        
        let symbol = isPasswordVisible ? "eye.fill" : "eye.slash.fill"
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let img = UIImage(systemName: symbol, withConfiguration: symbolConfig)
        passwordToggleButton?.setImage(img, for: .normal)
    }
}

