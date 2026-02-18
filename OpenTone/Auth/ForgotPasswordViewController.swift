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
        
        if let error = AuthValidator.validateEmail(emailField.text) {
             if let text = emailField.text, !text.isEmpty {
                 UIHelper.showError(message: error, on: emailField, in: view, nextView: resetButton)
             }
             isValid = false
        } else {
             UIHelper.clearError(on: emailField)
        }
        
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
        emailField.leftView = makeIconView(systemName: "envelope.fill")
        emailField.leftViewMode = .always
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
}
