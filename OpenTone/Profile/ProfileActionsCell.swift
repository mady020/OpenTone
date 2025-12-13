import UIKit

final class ProfileActionsCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()
    private let stackView = UIStackView()

    let settingsButton = UIButton(type: .system)
    let logoutButton = UIButton(type: .system)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        configureButton(settingsButton, title: "Settings")
        configureButton(logoutButton, title: "Log Out", destructive: true)

        stackView.addArrangedSubview(settingsButton)
        stackView.addArrangedSubview(logoutButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func configureButton(
        _ button: UIButton,
        title: String,
        destructive: Bool = false
    ) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1

        if destructive {
            button.setTitleColor(.systemRed, for: .normal)
            button.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            button.setTitleColor(UIColor(hex: "#5B3CC4"), for: .normal)
            button.layer.borderColor = UIColor(hex: "#5B3CC4").cgColor
        }
    }
}

