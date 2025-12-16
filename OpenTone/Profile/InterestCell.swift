import UIKit

final class InterestCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor(hex: "#333333")
        titleLabel.textAlignment = .center
    }

    func configure(title: String, selected: Bool = false) {
        titleLabel.text = title

        if selected {
            containerView.backgroundColor = UIColor(hex: "#5B3CC4")
            titleLabel.textColor = .white
            containerView.layer.borderColor = UIColor.clear.cgColor
        } else {
            containerView.backgroundColor = UIColor(hex: "#FBF8FF")
            titleLabel.textColor = UIColor(hex: "#333333")
            containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        }
    }
}

