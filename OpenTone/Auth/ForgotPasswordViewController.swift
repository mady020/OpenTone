import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!

    private var resetButton: UIButton?

    @IBAction func backToLoginTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addIconsToTextFields()
        setupUI()
        setupValidation()
    }
    
    private func setupUI() {
        UIHelper.styleViewController(self)
        UIHelper.styleTextField(emailField)
        UIHelper.styleLabels(in: view)
        
        findButtons(in: view).forEach { button in
            let actions = button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []
            let title = button.title(for: .normal)?.lowercased() ?? 
                        button.configuration?.title?.lowercased() ?? ""

            if actions.contains("backToLoginTapped:") {
                UIHelper.styleSecondaryButton(button)
            } else if title.contains("reset") || title.contains("send") {
                UIHelper.stylePrimaryButton(button)
                self.resetButton = button
            } else {
                // Determine based on context or leave as is if unknown, 
                // but for this screen, the other button is likely the primary action.
                UIHelper.stylePrimaryButton(button)
                self.resetButton = button
            }
        }
        
        validateInputs()
    }
    
    private func setupValidation() {
        emailField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    @objc private func textDidChange(_ sender: UITextField) {
        validateInputs()
    }
    
    private func validateInputs() {
        var isValid = true
        
        // Email Validation
        if let error = AuthValidator.validateEmail(emailField.text) {
             if let text = emailField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: emailField, in: view, nextView: resetButton)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: emailField)
        }
        
        // Update Button State
        if let button = resetButton {
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
    
    private func addIconsToTextFields() {
        let emailIcon = UIImageView(image: UIImage(systemName: "envelope.fill"))
        emailIcon.tintColor = .secondaryLabel
        let emailContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 22))
        emailIcon.frame = CGRect(x: 8, y: 0, width: 22, height: 22)
        emailContainer.addSubview(emailIcon)
        emailField.leftView = emailContainer
        emailField.leftViewMode = .always
    }
}
