
import UIKit

class TopicCell: UICollectionViewCell {
    
    @IBOutlet weak var tileLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        tileLabel.textColor = AppColors.textPrimary
        tileLabel.numberOfLines = 0
    }
}
