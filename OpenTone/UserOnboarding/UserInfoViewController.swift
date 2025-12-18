import UIKit

final class UserinfoViewController: UIViewController {

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

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#F4F5F7")

        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(hex: "#2E2E2E")

        nameField.backgroundColor = .white
        nameField.layer.cornerRadius = 14
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        nameField.font = .systemFont(ofSize: 18)
        nameField.setLeftPaddingPoints(16)

        countryField.setTitle("Select country", for: .normal)
        countryField.backgroundColor = .white
        countryField.layer.cornerRadius = 14
        countryField.layer.borderWidth = 1
        countryField.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        countryField.titleLabel?.font = .systemFont(ofSize: 18)
        countryField.setTitleColor(UIColor(hex: "#333333"), for: .normal)
        countryField.contentHorizontalAlignment = .left
        countryField.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        continueButton.layer.cornerRadius = 27
        continueButton.clipsToBounds = true
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
    }

    private func setupActions() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        countryField.addTarget(self, action: #selector(openCountryPicker), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    // MARK: - Session Sync

    /// Pre-fills UI from the current session user
    private func populateFromSession() {
        guard let user = SessionManager.shared.currentUser else { return }
        
        if let country = user.country {
            selectedCountry = country
            countryField.setTitle("\(country.flag) \(country.name)", for: .normal)
        }
    }

    // MARK: - Actions

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

        continueButton.isUserInteractionEnabled = valid
        continueButton.backgroundColor = valid
            ? UIColor(hex: "#5B3CC4")
            : UIColor(hex: "#C9C7D6")

        continueButton.setTitleColor(.white, for: .normal)
    }

    @objc private func continueTapped() {
        guard
            var user = SessionManager.shared.currentUser,
            let bio = nameField.text,
            let country = selectedCountry
        else { return }
        
        user.bio = bio
        user.country = country

        // Persist update to session
        SessionManager.shared.updateSessionUser(user)

        goToConfidenceChoice()
    }

    // MARK: - Navigation

    private func goToConfidenceChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ConfidenceScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITextField Padding Helper

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let padding = UIView(
            frame: CGRect(x: 0, y: 0, width: amount, height: frame.height)
        )
        leftView = padding
        leftViewMode = .always
    }
}

