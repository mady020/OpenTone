import UIKit

final class InterestCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()
    private let titleLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor(hex: "#333333")
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

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

