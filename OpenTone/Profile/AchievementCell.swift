import UIKit

final class AchievementCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(hex: "#5B3CC4")

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#333333")

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

