import UIKit

class SignupViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private var isPasswordVisible = false
    
    @IBAction func signupButtonTapped(_ sender: UIButton) {
    }
    @IBAction func signinButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        addIconsToTextFields()
        addPasswordToggle()
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(togglePasswordVisibility))
        container.addGestureRecognizer(tap)

        passwordField.rightView = container
        passwordField.rightViewMode = .always
    }

    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordField.isSecureTextEntry = !isPasswordVisible

        if let imageView = (passwordField.rightView)?.subviews.first as? UIImageView {
            imageView.image = UIImage(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
        }
    }

}
