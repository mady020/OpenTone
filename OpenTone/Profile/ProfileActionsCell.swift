import UIKit

final class ProfileActionsCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!

    enum Mode {
        case normal
        case postCall
        case inCall
        
        
    }
    
    func updateTimer(text: String) {
        timerLabel.text = text
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if logoutButton.backgroundColor != AppColors.primary {
                UIHelper.styleDestructiveButton(logoutButton)
                logoutButton.setTitle(logoutButton.title(for: .normal), for: .normal)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timerLabel.isHidden = true
        settingsButton.isHidden = false

        settingsButton.removeTarget(nil, action: nil, for: .allEvents)
        logoutButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        UIHelper.styleCardView(containerView)
        containerView.layer.shadowOpacity = 0
        containerView.layer.borderWidth = 0

        stackView.axis = .vertical
        stackView.spacing = 12

        timerLabel.isHidden = true
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.textColor = AppColors.primary

        configureButton(settingsButton, title: "Settings", destructive: false)
        configureButton(logoutButton, title: "Log Out", destructive: true)
    }

    func configure(mode: Mode, timerText: String? = nil) {
        settingsButton.removeTarget(nil, action: nil, for: .allEvents)
        logoutButton.removeTarget(nil, action: nil, for: .allEvents)

        switch mode {

        case .normal:
            timerLabel.isHidden = true
            settingsButton.isHidden = false

            configureButton(settingsButton, title: "Settings", destructive: false)
            configureButton(logoutButton, title: "Log Out", destructive: true)

        case .postCall:
            timerLabel.isHidden = true
            settingsButton.isHidden = false

            configureButton(settingsButton, title: "Start Call", destructive: false)
            configureButton(logoutButton, title: "Search Again", destructive: true)

        case .inCall:
            timerLabel.isHidden = false
            timerLabel.text = timerText ?? "00:00"

            settingsButton.isHidden = true
            configureButton(logoutButton, title: "End Call", destructive: true)
        }
    }

    func configureButton(
        _ button: UIButton,
        title: String,
        destructive: Bool
    ) {
        button.setTitle(title, for: .normal)

        if destructive {
            UIHelper.styleDestructiveButton(button)
        } else {
            UIHelper.styleSmallCTAButton(button)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        }
    }
}

