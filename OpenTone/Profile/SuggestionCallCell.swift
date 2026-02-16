import UIKit

final class SuggestionCallCell: UICollectionViewCell {


    @IBOutlet var containerView: UIView!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var labelView: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: SuggestionCallCell, _) in
            self.containerView.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = AppColors.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColors.cardBorder.cgColor

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColors.primary

        labelView.font = .systemFont(ofSize: 16, weight: .semibold)
        labelView.textColor = AppColors.textPrimary
    }

    func configure(
        title: String,
        icon: UIImage? = UIImage(systemName: "star.fill")
    ) {
        labelView.text = title
        imageView.image = icon
    }
}


