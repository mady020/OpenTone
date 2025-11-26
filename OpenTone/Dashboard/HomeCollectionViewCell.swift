import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel : UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 30
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
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

