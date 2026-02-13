import UIKit
class SelectableCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.masksToBounds = true
    }

    func configure(title: String, isSelected: Bool) {

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)

        if isSelected {
            contentView.backgroundColor = AppColors.primary
            titleLabel.textColor = AppColors.textOnPrimary
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = AppColors.cardBackground
            titleLabel.textColor = AppColors.textPrimary
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }
}
