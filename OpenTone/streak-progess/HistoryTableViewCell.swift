
import UIKit

class HistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
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
        subtitleLabel?.textColor = .secondaryLabel
        detailsLabel?.textColor = .secondaryLabel
    }

    func configure(with item: HistoryItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        detailsLabel.text = "⏱ \(item.duration)   ★ \(item.xp)"
        iconImageView.image = UIImage(systemName: item.iconName)
        iconImageView.tintColor = AppColors.primary
    }
}
