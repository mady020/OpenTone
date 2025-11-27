import UIKit

class RoleplaysCell: UICollectionViewCell {

    @IBOutlet weak var roleplayImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.layer.cornerRadius = 30
        contentView.clipsToBounds = true

 
        roleplayImageView.contentMode = .scaleAspectFill
        roleplayImageView.clipsToBounds = true

    
//        titleLabel.alpha = 0.4
        
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        

    }

    func configure(title: String, imageName: String) {
        titleLabel.text = title
        roleplayImageView.image = UIImage(named: imageName)
    }
}
