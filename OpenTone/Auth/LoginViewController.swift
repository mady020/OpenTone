import UIKit
import Foundation

final class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        addIconsToTextFields()
        addPasswordToggle()
    }

    // MARK: - Actions

    @IBAction func signinButtonTapped(_ sender: Any) {
        handleLogin()
    }

    // MARK: - Login Logic

    /// Handles login/signup logic and starts a session
    private func handleLogin() {
        guard
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            return
        }

        // For now: local-only login
        // Find existing user OR create a new one
        let user = resolveUser(email: email, password: password)

        // Start session
        SessionManager.shared.login(user: user)

        // Decide navigation
        routeAfterLogin()
    }

    /// Finds an existing user or creates a new one
    private func resolveUser(email: String, password: String) -> User {
        if let existingUser = UserDataModel.shared
            .allUsers
            .first(where: { $0.email == email }) {
            return existingUser
        }

        // New user signup (local)
        return User(
            name: "New User",
            email: email,
            password: password,
            country: nil
        )
    }

    /// Routes user to onboarding or dashboard
    private func routeAfterLogin() {
        guard let user = SessionManager.shared.currentUser else { return }

        // Simple onboarding condition (adjust later)
        let needsOnboarding = user.confidenceLevel == nil

        if needsOnboarding {
            goToUserInfo()
        } else {
            goToDashboard()
        }
    }

    // MARK: - Navigation

    /// Navigates to the main dashboard
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

    /// Navigates to the first onboarding screen
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

    // MARK: - UI Helpers

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

