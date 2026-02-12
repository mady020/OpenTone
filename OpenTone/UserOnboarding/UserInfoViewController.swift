import UIKit

final class UserinfoViewController: UIViewController {

    @IBOutlet var spacer: UIView?
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameField: UITextField!
    @IBOutlet private weak var countryField: UIButton!
    @IBOutlet private weak var continueButton: UIButton!

    private var selectedCountry: Country? {
        didSet { updateContinueState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        populateFromSession()
        updateContinueState()
        navigationItem.hidesBackButton = true
    }

    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground
        
        // Label styling will be handled by styleLabels or manual AppColors if specific
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        
        UIHelper.styleTextField(nameField)
        nameField.setLeftPaddingPoints(16) // Keep padding if needed, though styleTextField might handle some
        
        // Country Field (Button that looks like a field)
        UIHelper.styleSelectorButton(countryField)
        countryField.setTitle("Select country", for: .normal)

        // Continue Button
        UIHelper.stylePrimaryButton(continueButton)
        
        // Apply recursive label styling for other labels
        UIHelper.styleLabels(in: view)
        
        // Spacer styling (Handle unconnected outlet)
        spacer?.backgroundColor = AppColors.screenBackground
        
        // Fallback: Find generic UIViews (likely the spacer) that are not our main controls
        // and ensure they adapt to the screen background.
        view.subviews.forEach { subview in
            // Check if it's a plain UIView (not a Label, Button, Field, etc.)
            if type(of: subview) == UIView.self {
                subview.backgroundColor = AppColors.screenBackground
            }
        }
    }

    private func setupActions() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        countryField.addTarget(self, action: #selector(openCountryPicker), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    private func populateFromSession() {
        guard let user = SessionManager.shared.currentUser else { return }
        
        if let country = user.country {
            selectedCountry = country
            countryField.setTitle("\(country.flag) \(country.name)", for: .normal)
        }
    }

    @objc private func openCountryPicker() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CountryPickerViewController"
        ) as! CountryPickerViewController

        vc.onSelect = { [weak self] country in
            self?.selectedCountry = country
            self?.countryField.setTitle("\(country.flag) \(country.name)", for: .normal)
        }

        present(vc, animated: true)
    }

    @objc private func nameChanged() {
        updateContinueState()
    }

    private func updateContinueState() {
        let valid = !(nameField.text ?? "").isEmpty && selectedCountry != nil
        UIHelper.setButtonState(continueButton, enabled: valid)
    }

    @objc private func continueTapped() {
        guard
            var user = SessionManager.shared.currentUser,
            let bio = nameField.text,
            let country = selectedCountry
        else { return }
        
        user.bio = bio
        user.country = country
        SessionManager.shared.updateSessionUser(user)

        goToConfidenceChoice()
    }

    private func goToConfidenceChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ConfidenceScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let padding = UIView(
            frame: CGRect(x: 0, y: 0, width: amount, height: frame.height)
        )
        leftView = padding
        leftViewMode = .always
    }
}

