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
    }

    func configure(title: String, imageName: String) {
      
        titleLabel.font = UIFont.systemFont(ofSize: 14 , weight: .bold)
        
        titleLabel.text = title
        roleplayImageView.image = UIImage(named: imageName)
    }
  
}
