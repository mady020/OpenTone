import UIKit

/// The type of saved session to display in the continue card.
enum SavedSessionType {
    case jam(topic: String, secondsLeft: Int, phase: JamPhase)
    case roleplay(scenarioTitle: String, progress: Int, total: Int)
}

/// A dashboard card that shows a saved session and lets the user continue it.
final class ContinueJamCell: UICollectionViewCell {

    static let reuseID = "ContinueJamCell"

    // MARK: - Subviews

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = AppColors.primary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let typeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = AppColors.primary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let topicLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldSystemFont(ofSize: 16)
        lbl.textColor = AppColors.textPrimary
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let timeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let continueButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        btn.setTitleColor(AppColors.textOnPrimary, for: .normal)
        btn.backgroundColor = AppColors.primary
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Callback

    var onContinueTapped: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        clipsToBounds = true

        let textStack = UIStackView(arrangedSubviews: [typeLabel, topicLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(continueButton)

        NSLayoutConstraint.activate([
            // Icon on the left
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            // Text stack in the middle
            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: continueButton.leadingAnchor, constant: -8),

            // Continue button on the right
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            continueButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 90),
            continueButton.heightAnchor.constraint(equalToConstant: 34),
        ])

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    @objc private func continueTapped() {
        onContinueTapped?()
    }

    // MARK: - Configure (legacy jam-only)

    func configure(topic: String, secondsLeft: Int, phase: JamPhase) {
        configure(with: .jam(topic: topic, secondsLeft: secondsLeft, phase: phase))
    }

    // MARK: - Configure (generic)

    func configure(with sessionType: SavedSessionType) {
        switch sessionType {
        case .jam(let topic, let secondsLeft, let phase):
            iconImageView.image = UIImage(systemName: "mic.fill")
            typeLabel.text = "2-Minute JAM"
            topicLabel.text = topic
            let phaseText = phase == .preparing ? "Prepare" : "Speak"
            timeLabel.text = "\(phaseText) • \(secondsLeft)s remaining"

        case .roleplay(let scenarioTitle, let progress, let total):
            iconImageView.image = UIImage(systemName: "theatermasks.fill")
            typeLabel.text = "Roleplay"
            topicLabel.text = scenarioTitle
            timeLabel.text = "\(progress)/\(total) lines completed"
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
        }
    }
}
