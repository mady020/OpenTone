import UIKit

final class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false

    private var loginButton: UIButton?

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
                UIHelper.styleAppleButton(button)
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
        handleQuickSignIn()
    }

    
    
    private func handleQuickSignIn() {
        // Get the first sample user who has complete onboarding data
        guard let sampleUser = UserDataModel.shared.getSampleUserForQuickSignIn() else {
            let alert = UIAlertController(title: "Error", message: "Could not load sample user", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        SessionManager.shared.login(user: sampleUser)
        goToDashboard()
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

        guard let user = UserDataModel.shared.authenticate(
            email: email,
            password: password
        ) else {
            // show "Invalid email or password"
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
        let emailIcon = UIImageView(image: UIImage(systemName: "envelope.fill"))
        emailIcon.tintColor = .secondaryLabel
        let emailContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 22))
        emailIcon.frame = CGRect(x: 8, y: 0, width: 22, height: 22)
        emailContainer.addSubview(emailIcon)
        emailField.leftView = emailContainer
        emailField.leftViewMode = .always

        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = .secondaryLabel
        let lockContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 22))
        lockIcon.frame = CGRect(x: 8, y: 0, width: 22, height: 22)
        lockContainer.addSubview(lockIcon)
        passwordField.leftView = lockContainer
        passwordField.leftViewMode = .always
    }

    private func addPasswordToggle() {
        let eyeIcon = UIImageView(image: UIImage(systemName: "eye.slash.fill"))
        eyeIcon.tintColor = .secondaryLabel
        eyeIcon.isUserInteractionEnabled = true

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        eyeIcon.frame = CGRect(x: 8, y: 8, width: 20, height: 20)
        container.addSubview(eyeIcon)

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(togglePasswordVisibility)
        )
        container.addGestureRecognizer(tap)

        passwordField.rightView = container
        passwordField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordField.isSecureTextEntry = !isPasswordVisible

        if let imageView = passwordField.rightView?.subviews.first as? UIImageView {
            imageView.image = UIImage(
                systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill"
            )
        }
    }
}

