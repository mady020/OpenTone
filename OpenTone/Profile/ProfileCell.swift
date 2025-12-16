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

            containerView.backgroundColor = UIColor(hex: "#FBF8FF")
            containerView.layer.cornerRadius = 16
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

            avatarImageView.layer.cornerRadius = 32
            avatarImageView.clipsToBounds = true
            avatarImageView.contentMode = .scaleAspectFill

            nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            nameLabel.textColor = UIColor(hex: "#333333")

            countryLabel.font = .systemFont(ofSize: 14)
            countryLabel.textColor = .secondaryLabel

            levelLabel.font = .systemFont(ofSize: 14, weight: .medium)
            levelLabel.textColor = UIColor(hex: "#5B3CC4")

            bioLabel.font = .systemFont(ofSize: 14)
            bioLabel.textColor = UIColor(hex: "#333333")
            bioLabel.numberOfLines = 0

            streakLabel.font = .systemFont(ofSize: 13, weight: .medium)
            streakLabel.textColor = UIColor(hex: "#5B3CC4")
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

