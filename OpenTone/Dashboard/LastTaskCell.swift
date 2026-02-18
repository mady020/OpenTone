import UIKit

class LastTaskCell: UICollectionViewCell {


    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!

    var onContinueTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false

        contentView.backgroundColor = AppColors.cardBackground
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        typeLabel.textColor = AppColors.primary
        titleLabel.textColor = AppColors.textPrimary
        iconImageView.tintColor = AppColors.primary
        UIHelper.styleSmallCTAButton(continueButton)
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
