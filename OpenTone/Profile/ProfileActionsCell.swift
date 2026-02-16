import UIKit

final class ProfileActionsCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!

    enum Mode {
        case normal        // Settings / Log Out
        case postCall      // Start Call / Search Again
        case inCall        // Timer + End Call
        
        
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
            // Re-apply destructive button border
            if logoutButton.backgroundColor != AppColors.primary {
                logoutButton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
            }
            if settingsButton.backgroundColor != AppColors.primary {
                settingsButton.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
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
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true

        if destructive {
            button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            button.setTitleColor(.systemRed, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        } else {
            button.backgroundColor = AppColors.primary
            button.setTitleColor(AppColors.textOnPrimary, for: .normal)
            button.layer.borderWidth = 0
            button.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

