import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel : UILabel!
    private let baseCardColor  = UIColor(hex: "#FBF8FF")

    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = baseCardColor
        layer.cornerRadius = 30
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        textLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    
    func configure(title: String) {
            textLabel.text = title
            
            if title.lowercased() == "roleplays" {
                textLabel.font = UIFont.systemFont(ofSize: 14 , weight: .bold)
            }
        }
    
    
}

