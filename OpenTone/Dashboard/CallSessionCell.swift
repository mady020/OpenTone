import UIKit

class CallSessionCell: UICollectionViewCell {
    

    
    @IBOutlet var image: UIImageView!
    
    @IBOutlet var buttonLabel: UILabel!
    
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

        buttonLabel.textColor = AppColors.textPrimary
        buttonLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        image.tintColor = AppColors.primary

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: CallSessionCell, _) in
            self.layer.borderColor = AppColors.cardBorder.cgColor
        }
    }
    
     func configure(imageURL: String, labelText: String){
        image.image = UIImage(systemName: imageURL)
        buttonLabel.text = labelText
    }
    
}
