import UIKit
class SelectableCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
    }

    func configure(title: String, isSelected: Bool) {

        titleLabel.text = title

        if isSelected {
            contentView.backgroundColor = UIColor(
                red: 212/255,
                green: 164/255,
                blue: 255/255,
                alpha: 1.0
            )

            titleLabel.textColor = .white
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = .white
            titleLabel.textColor = .darkGray
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.gray.cgColor
        }
    }
}
