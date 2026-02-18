import UIKit

enum SavedSessionType {
    case jam(topic: String, secondsLeft: Int, phase: JamPhase)
    case roleplay(scenarioTitle: String, progress: Int, total: Int)
}

final class ContinueJamCell: UICollectionViewCell {

    static let reuseID = "ContinueJamCell"


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
        btn.translatesAutoresizingMaskIntoConstraints = false
        UIHelper.styleSmallCTAButton(btn)
        return btn
    }()


    var onContinueTapped: (() -> Void)?


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }


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
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: continueButton.leadingAnchor, constant: -8),

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


    func configure(topic: String, secondsLeft: Int, phase: JamPhase) {
        configure(with: .jam(topic: topic, secondsLeft: secondsLeft, phase: phase))
    }


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
