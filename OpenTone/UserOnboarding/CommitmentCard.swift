//
//  CommitmentCard.swift
//  OpenTone
//
//  Created by M S on 05/12/25.
//


import UIKit

final class CommitmentCard: UICollectionViewCell {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 1

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),

            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with option: CommitmentOption,
                   backgroundColor: UIColor?,
                   tintColor: UIColor?,
                   borderColor: UIColor?) {
        self.backgroundColor = backgroundColor
        self.layer.borderColor = borderColor?.cgColor
        titleLabel.textColor = tintColor
        subtitleLabel.textColor = tintColor?.withAlphaComponent(0.8)
        titleLabel.text = option.title
        subtitleLabel.text = option.subtitle
    }
}
