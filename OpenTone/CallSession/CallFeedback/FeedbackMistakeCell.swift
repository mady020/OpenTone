import UIKit

class FeedbackMistakeCell: UICollectionViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
    }
}

