import UIKit

class DescriptionCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = AppColors.cardBackground
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColors.cardBorder.cgColor
        descriptionLabel.textColor = AppColors.textPrimary
        timeLabel.textColor = .secondaryLabel
    }

    func configure(description: String, time: String) {
        descriptionLabel.text = description
        timeLabel.text = time
    }
}
