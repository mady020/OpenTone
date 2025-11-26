import UIKit

class InterestChipCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configure(_ text: String) {
        titleLabel.text = text
    }
}
