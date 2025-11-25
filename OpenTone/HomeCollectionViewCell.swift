import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel : UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Card appearance
        contentView.layer.cornerRadius = 30
        contentView.clipsToBounds = true
        
        // Image setup
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
//        imageView.alpha = 1.8
        textLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        
        // Ensure image stretches to full cell
//        imageView.translatesAutoresizingMaskIntoConstraints = false
        
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        ])
//        
    }
    
    
    func configure(title: String) {
            textLabel.text = title
            
            if title.lowercased() == "roleplays" {
                textLabel.font = UIFont.systemFont(ofSize: 14 , weight: .bold)
            }
        }
    
    
}

