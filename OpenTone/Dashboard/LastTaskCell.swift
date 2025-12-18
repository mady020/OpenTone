import UIKit

class LastTaskCell: UICollectionViewCell {


    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!

    var onContinueTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 30
        clipsToBounds = true
        continueButton.clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
    }

    @IBAction func continueTapped(_ sender: UIButton) {
        onContinueTapped?()
    }
    
    func configure(title: String, imageURL: String) {
        titleLabel.text = title

        // If imageURL is a system image name
        iconImageView.image = UIImage(systemName: imageURL)

        // If later you move to remote images, this method stays the same
    }


   
}
