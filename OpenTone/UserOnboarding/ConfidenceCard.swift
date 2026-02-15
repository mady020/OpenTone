import UIKit

final class ConfidenceCard: UICollectionViewCell {


    @IBOutlet private weak var emojiLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            contentView.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.clipsToBounds = true

        emojiLabel.font = .systemFont(ofSize: 30)

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 1
    }

    func configure(
        option: ConfidenceOption,
        backgroundColor: UIColor,
        textColor: UIColor,
        borderColor: UIColor
    ) {
        emojiLabel.text = option.emoji
        titleLabel.text = option.title

        contentView.backgroundColor = backgroundColor
        contentView.layer.borderColor = borderColor.cgColor

        titleLabel.textColor = textColor
        emojiLabel.textColor = textColor
    }
}
