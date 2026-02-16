import UIKit

final class InterestCard: UICollectionViewCell {

    static let reuseIdentifier = "InterestCard"
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: InterestCard, _) in
            self.containerView.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.transform = .identity
        containerView.layer.borderWidth = 1
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        iconView.contentMode = .scaleAspectFit
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 1
    }

    func configure(
        with item: InterestItem,
        backgroundColor: UIColor,
        tintColor: UIColor,
        borderColor: UIColor,
        selected: Bool
    ) {
        iconView.image = UIImage(systemName: item.symbol)
        iconView.tintColor = tintColor

        titleLabel.text = item.title
        titleLabel.textColor = tintColor

        containerView.backgroundColor = backgroundColor
        containerView.layer.borderWidth = selected ? 0 : 1
        containerView.layer.borderColor = borderColor.cgColor

        UIView.animate(withDuration: 0.18) {
            self.containerView.transform = selected
                ? CGAffineTransform(scaleX: 0.985, y: 0.985)
                : .identity
        }
    }
}

