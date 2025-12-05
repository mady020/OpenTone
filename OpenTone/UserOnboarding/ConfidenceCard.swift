import UIKit

final class ConfidenceCard: UICollectionViewCell {

    private let titleLabel = UILabel()
    private let emojiLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 1

        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with option: ConfidenceOption,
                   backgroundColor: UIColor,
                   tintColor: UIColor,
                   borderColor: UIColor,
                   selected: Bool) {
        emojiLabel.text = option.emoji
        titleLabel.text = option.title
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.layer.borderColor = borderColor.cgColor
        titleLabel.textColor = tintColor
    }
}
