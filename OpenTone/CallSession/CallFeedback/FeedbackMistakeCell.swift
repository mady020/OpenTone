import UIKit

class FeedbackMistakeCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackMistakeCell, _) in
            self.applyTheme()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 24
        clipsToBounds = true
    }



    private func applyTheme() {
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.backgroundColor = AppColors.cardBackground.cgColor
    }
}

