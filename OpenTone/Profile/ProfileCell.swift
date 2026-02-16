import UIKit

final class ProfileCell: UICollectionViewCell {


    @IBOutlet var containerView: UIView!
    
    @IBOutlet var avatarImageView: UIImageView!
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var countryLabel: UILabel!
    
    @IBOutlet var levelLabel: UILabel!
    
    @IBOutlet var bioLabel: UILabel!
    
    @IBOutlet var streakLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            avatarImageView.layer.borderColor = AppColors.primary.cgColor
        }
    }


    private func setupUI() {
            contentView.backgroundColor = .clear

            UIHelper.styleCardView(containerView)
            containerView.layer.shadowOpacity = 0
            containerView.layer.borderWidth = 0

            avatarImageView.layer.cornerRadius = 32
            avatarImageView.clipsToBounds = true
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.layer.borderWidth = 2
            avatarImageView.layer.borderColor = AppColors.primary.cgColor

            nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
            nameLabel.textColor = AppColors.textPrimary

            countryLabel.font = .systemFont(ofSize: 14)
            countryLabel.textColor = .secondaryLabel

            levelLabel.font = .systemFont(ofSize: 15, weight: .medium)
            levelLabel.textColor = AppColors.primary

            bioLabel.font = .systemFont(ofSize: 14)
            bioLabel.textColor = AppColors.textPrimary
            bioLabel.numberOfLines = 0

            streakLabel.font = .systemFont(ofSize: 13, weight: .medium)
            streakLabel.textColor = AppColors.primary
        }

    


    func configure(
        name: String,
        country: String,
        level: String,
        bio: String,
        streakText: String,
        avatar: UIImage?,
        isPeer: Bool = false
    ) {
        nameLabel.text = name
        countryLabel.text = country
        levelLabel.text = level
        bioLabel.text = bio
        streakLabel.text = streakText
        avatarImageView.image = avatar

        if isPeer {
            containerView.backgroundColor = AppColors.primaryLight
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = AppColors.primary.withAlphaComponent(0.3).cgColor
            avatarImageView.layer.borderWidth = 3
            avatarImageView.layer.borderColor = AppColors.primary.cgColor
            nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        }
    }
}

