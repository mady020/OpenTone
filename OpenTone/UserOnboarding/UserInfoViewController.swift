import UIKit

final class UserinfoViewController: UIViewController {

    // MARK: - UI
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tell us about you"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = UIColor(hex: "#2E2E2E")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your name"
        tf.backgroundColor = UIColor(hex: "#FFFFFF")
        tf.layer.cornerRadius = 14
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        tf.font = .systemFont(ofSize: 18)
        tf.setLeftPaddingPoints(16)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let countryField: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Select country", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18)
        btn.tintColor = UIColor(hex: "#333333")
        btn.backgroundColor = UIColor(hex: "#FFFFFF")
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        btn.contentHorizontalAlignment = .left
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let continueButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.layer.cornerRadius = 18
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let spacer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - State
    private var selectedCountry: Country? = nil {
        didSet { updateContinueState() }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F4F5F7")

        setupLayout()
        setupActions()
        updateContinueState()
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(nameField)
        view.addSubview(countryField)
        view.addSubview(spacer)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 54),

            countryField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 18),
            countryField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            countryField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            countryField.heightAnchor.constraint(equalToConstant: 54),

            spacer.topAnchor.constraint(equalTo: countryField.bottomAnchor),
            spacer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spacer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spacer.bottomAnchor.constraint(equalTo: continueButton.topAnchor),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            continueButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        countryField.addTarget(self, action: #selector(openCountryPicker), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    @objc private func openCountryPicker() {
        let vc = CountryPickerViewController()
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
        continueButton.backgroundColor = valid ? UIColor(hex: "#5B3CC4") : UIColor(hex: "#C9C7D6")
        continueButton.tintColor = .white
    }

    private func goToConfidenceChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let introVC = storyboard.instantiateViewController(withIdentifier: "ConfidenceScreen")
        let nav = UINavigationController(rootViewController: introVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.view.window?.rootViewController = nav
        self.view.window?.makeKeyAndVisible()
    }

    @objc private func continueTapped() {
        guard selectedCountry != nil else { return }
        goToConfidenceChoice()
    }
}

// MARK: - Padding helper
private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        leftView = padding
        leftViewMode = .always
    }
}

