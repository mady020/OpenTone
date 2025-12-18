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


    private func setupUI() {
            contentView.backgroundColor = .clear

            containerView.backgroundColor = AppColors.cardBackground
            containerView.layer.cornerRadius = 16
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = AppColors.cardBorder.cgColor

            avatarImageView.layer.cornerRadius = 32
            avatarImageView.clipsToBounds = true
            avatarImageView.contentMode = .scaleAspectFill

            nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            nameLabel.textColor = AppColors.textPrimary

            countryLabel.font = .systemFont(ofSize: 14)
            countryLabel.textColor = .secondaryLabel

            levelLabel.font = .systemFont(ofSize: 14, weight: .medium)
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
        avatar: UIImage?
    ) {
        nameLabel.text = name
        countryLabel.text = country
        levelLabel.text = level
        bioLabel.text = bio
        streakLabel.text = streakText
        avatarImageView.image = avatar
    }
}

