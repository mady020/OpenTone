import UIKit

class InterestChipCell: UICollectionViewCell {
    static let reuseId = "InterestChipCell"

    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.systemGray5
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(text: String) {
        label.text = text
    }
}
