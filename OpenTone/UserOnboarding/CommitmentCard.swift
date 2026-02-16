import UIKit

final class CommitmentCard: UICollectionViewCell {

    static let reuseIdentifier = "CommitmentCard"

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 16
        layer.borderWidth = 1
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: CommitmentCard, _) in
            self.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    func configure(
        with option: CommitmentOption,
        backgroundColor: UIColor,
        tintColor: UIColor,
        borderColor: UIColor
    ) {
        self.backgroundColor = backgroundColor
        layer.borderColor = borderColor.cgColor

        titleLabel.text = option.title
        subtitleLabel.text = option.subtitle

        titleLabel.textColor = tintColor
        subtitleLabel.textColor = tintColor.withAlphaComponent(0.8)
    }
}

