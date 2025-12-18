import UIKit

class FeedbackMistakeCell: UICollectionViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 24
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.backgroundColor = AppColors.cardBackground.cgColor
    }
}

