import UIKit

final class InterestCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        UIHelper.styleCardView(containerView)
        containerView.layer.shadowOpacity = 0
        containerView.layer.borderWidth = 0

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center
    }

    func configure(title: String, selected: Bool = false) {
        titleLabel.text = title

        if selected {
            containerView.backgroundColor = AppColors.primary
            titleLabel.textColor = .white
        } else {
            containerView.backgroundColor = AppColors.cardBackground
            titleLabel.textColor = AppColors.textPrimary
        }
    }
}

