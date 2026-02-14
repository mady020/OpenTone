




import UIKit

class SectionHeaderView: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
    }
}

