import UIKit

final class ProfileCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()

    private let avatarImageView = UIImageView()

    private let nameLabel = UILabel()
    private let countryLabel = UILabel()
    private let levelLabel = UILabel()
    private let bioLabel = UILabel()
    private let streakLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = UIColor(hex: "#E6E3EE")

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor(hex: "#333333")

        countryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        countryLabel.textColor = .secondaryLabel

        levelLabel.font = .systemFont(ofSize: 14, weight: .medium)
        levelLabel.textColor = UIColor(hex: "#5B3CC4")

        bioLabel.font = .systemFont(ofSize: 14)
        bioLabel.textColor = UIColor(hex: "#333333")
        bioLabel.numberOfLines = 0

        streakLabel.font = .systemFont(ofSize: 13, weight: .medium)
        streakLabel.textColor = UIColor(hex: "#5B3CC4")

        [avatarImageView,
         nameLabel,
         countryLabel,
         levelLabel,
         bioLabel,
         streakLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
    }

    private func setupConstraints() {

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 64),
            avatarImageView.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            levelLabel.topAnchor.constraint(equalTo: countryLabel.bottomAnchor, constant: 4),
            levelLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            bioLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            bioLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            streakLabel.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 12),
            streakLabel.leadingAnchor.constraint(equalTo: bioLabel.leadingAnchor),
            streakLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

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

