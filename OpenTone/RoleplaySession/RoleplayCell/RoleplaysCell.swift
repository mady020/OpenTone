import UIKit

class RoleplaysCell: UICollectionViewCell {

    @IBOutlet weak var roleplayImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    private let baseCardColor  = UIColor(hex: "#FBF8FF")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = baseCardColor
        layer.cornerRadius = 30
        clipsToBounds = true
        roleplayImageView.contentMode = .scaleAspectFill
        roleplayImageView.clipsToBounds = true
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        roleplayImageView.contentMode = .scaleAspectFill
        roleplayImageView.layer.cornerRadius = 30
        roleplayImageView.clipsToBounds = true

        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 2
        
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
    }

    func configure(title: String, imageName: String) {
      
        titleLabel.font = UIFont.systemFont(ofSize: 14 , weight: .bold)
        
        titleLabel.text = title
        roleplayImageView.image = UIImage(named: imageName)
    }
  
}
