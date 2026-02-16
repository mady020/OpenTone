import UIKit

class AchievementCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = AppColors.cardBackground
        containerView.layer.cornerRadius = 16

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AppColors.primary

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
    }

    func configure(
        title: String,
        subtitle: String,
        icon: UIImage? = UIImage(systemName: "star.fill")
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconView.image = icon
    }
}

