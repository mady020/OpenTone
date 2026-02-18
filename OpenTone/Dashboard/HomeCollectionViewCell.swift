import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!


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

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        textLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        textLabel.numberOfLines = 2

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: HomeCollectionViewCell, _) in
            self.layer.borderColor = AppColors.cardBorder.cgColor
        }
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
