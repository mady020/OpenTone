import UIKit

class FeedbackMistakeCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 24
        clipsToBounds = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    private func applyTheme() {
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.backgroundColor = AppColors.cardBackground.cgColor
    }
}

