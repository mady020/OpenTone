import UIKit

class HighlightsCardCell: UICollectionViewCell {

    static let reuseId = "HighlightsCardCell"
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldSystemFont(ofSize: 18)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = UIColor.white.withAlphaComponent(0.85)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.layer.cornerRadius = 22
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
        
        // Soft shadow (on outer layer)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.masksToBounds = false
    }

    func configure(with item: HighlightItem) {
        iconView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        contentView.backgroundColor = item.color
    }
}
