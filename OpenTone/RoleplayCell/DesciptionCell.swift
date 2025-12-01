import UIKit

class DescriptionCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = .systemGray6
    }

    func configure(description: String, time: String) {
        descriptionLabel.text = description
        timeLabel.text = time
        timeLabel.textColor = .systemGreen
    }
}
