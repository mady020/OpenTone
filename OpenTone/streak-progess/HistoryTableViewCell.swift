
import UIKit

class HistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

    // Programmatic subviews for the improved design
    private let timestampLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = .tertiaryLabel
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let typeBadge: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 10, weight: .bold)
        lbl.textColor = AppColors.primary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let continueIndicator: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private var hasAddedProgrammaticViews = false

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        addProgrammaticSubviews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    private func applyTheme() {
        cardBackgroundView?.layer.cornerRadius = 16
        cardBackgroundView?.clipsToBounds = true
        cardBackgroundView?.backgroundColor = AppColors.cardBackground
        cardBackgroundView?.layer.borderWidth = 1
        cardBackgroundView?.layer.borderColor = AppColors.cardBorder.cgColor

        titleLabel?.textColor = AppColors.textPrimary
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel?.textColor = .secondaryLabel
        subtitleLabel?.font = .systemFont(ofSize: 13)
        detailsLabel?.textColor = .secondaryLabel
        detailsLabel?.font = .systemFont(ofSize: 12, weight: .medium)
    }

    private func addProgrammaticSubviews() {
        guard !hasAddedProgrammaticViews else { return }
        hasAddedProgrammaticViews = true

        guard let card = cardBackgroundView else { return }
        card.addSubview(timestampLabel)
        card.addSubview(typeBadge)
        card.addSubview(continueIndicator)

        NSLayoutConstraint.activate([
            // Timestamp top-right
            timestampLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            timestampLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            // Type badge below icon area
            typeBadge.leadingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -2),
            typeBadge.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),

            // Continue chevron on the right, vertically centered
            continueIndicator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            continueIndicator.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            continueIndicator.widthAnchor.constraint(equalToConstant: 12),
            continueIndicator.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    func configure(with item: HistoryItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.topic
        detailsLabel.text = "⏱ \(item.duration)   ★ \(item.xp)"
        iconImageView.image = UIImage(systemName: item.iconName)
        iconImageView.tintColor = AppColors.primary

        // Timestamp
        timestampLabel.text = item.timeString

        // Type badge
        if let type = item.activityType {
            typeBadge.isHidden = false
            switch type {
            case .call:
                typeBadge.text = "CALL"
                typeBadge.textColor = .systemGreen
            case .jam:
                typeBadge.text = "JAM"
                typeBadge.textColor = AppColors.primary
            case .roleplay:
                typeBadge.text = "ROLEPLAY"
                typeBadge.textColor = .systemOrange
            }
        } else {
            typeBadge.isHidden = true
        }

        // Show continue chevron for incomplete roleplay items
        continueIndicator.isHidden = (item.scenarioId == nil)
    }
}
