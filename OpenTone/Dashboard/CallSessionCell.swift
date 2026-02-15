import UIKit

class CallSessionCell: UICollectionViewCell {
    

    
    @IBOutlet var image: UIImageView!
    
    @IBOutlet var buttonLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = 30
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor

        buttonLabel.textColor = AppColors.textPrimary
        buttonLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        image.tintColor = AppColors.primary
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
        }
    }
    
     func configure(imageURL: String, labelText: String){
        image.image = UIImage(systemName: imageURL)
        buttonLabel.text = labelText
    }
    
}
