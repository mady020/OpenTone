import UIKit

class InterestChipCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        // Rounded chip style
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemGray6

        // Proper text sizing behavior
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        // Ensure auto-sizing works perfectly
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configure(_ text: String) {
        titleLabel.text = text
    }
}
