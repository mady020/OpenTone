import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = AppColors.cardBackground
        layer.cornerRadius = 30
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true

        textLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        textLabel.numberOfLines = 2
        
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        textLabel.text = nil
    }
    func configure(with scenario: RoleplayScenario) {
        textLabel.text = scenario.title
        imageView.image = UIImage(named: scenario.imageURL)
    }
}
