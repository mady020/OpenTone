
import UIKit

class HistoryTableViewCell: UITableViewCell {

    
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            cardBackgroundView?.layer.cornerRadius = 12
            cardBackgroundView?.clipsToBounds = true
        }

        func configure(with item: HistoryItem) {
            titleLabel.text = item.title
            subtitleLabel.text = item.subtitle
            detailsLabel.text = "⏱ Duration: \(item.duration)   ★ \(item.xp)"
            iconImageView.image = UIImage(systemName: item.iconName)
            iconImageView.tintColor = .systemPurple
        }
    }

