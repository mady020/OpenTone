import UIKit

final class SuggestionCallCell: UICollectionViewCell {


    @IBOutlet var containerView: UIView!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var labelView: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(hex: "#5B3CC4")

        labelView.font = .systemFont(ofSize: 16, weight: .semibold)
        labelView.textColor = UIColor(hex: "#333333")
    }

    func configure(
        title: String,
        icon: UIImage? = UIImage(systemName: "star.fill")
    ) {
        labelView.text = title
        imageView.image = icon
    }
}


