import UIKit

class CallSessionCell: UICollectionViewCell {
    

    
    @IBOutlet var image: UIImageView!
    
    @IBOutlet var buttonLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Cell layer: shadow + border (no clipping)
        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false

        // Content view: clips content
        contentView.backgroundColor = AppColors.cardBackground
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

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
