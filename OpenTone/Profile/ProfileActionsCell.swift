import UIKit

final class ProfileActionsCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!


    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

        stackView.axis = .vertical
        stackView.spacing = 12

        configureButton(settingsButton, title: "Settings", destructive: false)
        configureButton(logoutButton, title: "Log Out", destructive: true)
    }

    private func configureButton(
        _ button: UIButton,
        title: String,
        destructive: Bool
    ) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1

        if destructive {
            button.setTitleColor(.systemRed, for: .normal)
            button.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            let accent = UIColor(hex: "#5B3CC4")
            button.setTitleColor(accent, for: .normal)
            button.layer.borderColor = accent.cgColor
        }
    }
}

