import UIKit

class LastTaskCell: UICollectionViewCell {


    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!

    var onContinueTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = 30
        clipsToBounds = true
        continueButton.clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor

        typeLabel.textColor = AppColors.primary
        titleLabel.textColor = AppColors.textPrimary
        iconImageView.tintColor = AppColors.primary
        continueButton.backgroundColor = AppColors.primary
        continueButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        continueButton.layer.cornerRadius = 14
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
        }
    }

    @IBAction func continueTapped(_ sender: UIButton) {
        onContinueTapped?()
    }
    
    func configure(title: String, imageURL: String) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: imageURL)
    }


   
}
