import UIKit

final class SignupViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false

    private var signupButton: UIButton?

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
                UIHelper.styleAppleButton(button)
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
                 // Push password field down
                 UIHelper.showError(message: error, on: emailField, in: view, nextView: passwordField)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: emailField)
        }
        
        // Password Validation
        if let error = AuthValidator.validatePassword(passwordField.text) {
             if let text = passwordField.text, !text.isEmpty {
                 // Push button down (if constraint exists to signupButton)
                 // Note: we need to find the specific button instance.
                 // We stored `signupButton` in `viewDidLoad`.
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

        let user = User(
            name: name,
            email: email,
            password: password,
            country: nil,
            avatar: "pp1"
        )

        let success = UserDataModel.shared.registerUser(user)
        guard success else {
            showUserExistsAlert()
            return
        }

        goToUserInfo()
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

    private func goToUserInfo() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let userInfoVC = storyboard.instantiateViewController(
            withIdentifier: "UserInfoScreen"
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



    private func addIconsToTextFields() {
        let nameIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        nameIcon.tintColor = .secondaryLabel
        let nameContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 22))
        nameIcon.frame = CGRect(x: 8, y: 0, width: 22, height: 22)
        nameContainer.addSubview(nameIcon)
        nameField.leftView = nameContainer
        nameField.leftViewMode = .always

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

