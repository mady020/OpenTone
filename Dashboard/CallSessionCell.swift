import UIKit

final class CallSessionCell: UICollectionViewCell {

    static let reuseID = "CallSessionCell"

    // MARK: - UI Elements

    private let iconContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 16)
        l.textColor = AppColors.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        iv.tintColor = .tertiaryLabel
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        // Flat card style — matches ContinueJamCell / other dashboard cards
        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        clipsToBounds = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            // Icon container — left, vertically centered
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            // Icon image inside container
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            // Text stack — vertically centered between icon and arrow
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),

            // Arrow — right, vertically centered
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 14),
            arrowImageView.heightAnchor.constraint(equalToConstant: 14),
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: CallSessionCell, _) in
            self.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    // MARK: - Configure

    func configure(icon: String, title: String, subtitle: String, iconBackground: UIColor = AppColors.primary) {
        iconImageView.image = UIImage(
            systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        )
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconContainer.backgroundColor = iconBackground
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
        }
    }
}
