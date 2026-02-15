import UIKit

final class CommitmentCard: UICollectionViewCell {

    static let reuseIdentifier = "CommitmentCard"

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 16
        layer.borderWidth = 1
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
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

