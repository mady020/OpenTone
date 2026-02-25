import UIKit

/// Section 1 — Big Result Card
/// Shows overall score, direction arrow, and a one-line summary.
class FeedbackHeaderCell: UICollectionViewCell {
    
    static let reuseID = "FeedbackHeaderCell"
    
    // MARK: - Views
    
    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 64, weight: .black)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        return l
    }()
    
    private let labelStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .center
        return s
    }()
    
    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.text = "OVERALL SCORE"
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    
    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 24
        v.layer.cornerCurve = .continuous
        return v
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    
    private func setup() {
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        labelStack.addArrangedSubview(categoryLabel)
        labelStack.addArrangedSubview(scoreLabel)
        labelStack.addArrangedSubview(subtitleLabel)
        // Apply letter spacing after adding to hierarchy
        categoryLabel.attributedText = NSAttributedString(
            string: "OVERALL SCORE",
            attributes: [.kern: 1.2, .foregroundColor: UIColor.secondaryLabel,
                         .font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
        card.addSubview(labelStack)
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            labelStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 32),
            labelStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            labelStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            labelStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -32),
        ])
        
        applyStyle()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackHeaderCell, _) in self.applyStyle() }
    }
    
    private func applyStyle() {
        card.backgroundColor = AppColors.cardBackground
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.cardBorder.cgColor
    }
    
    // MARK: - Configure
    
    func configure(score: Double, direction: String, summary: String) {
        let arrow: String
        let color: UIColor
        switch direction {
        case "improving": arrow = " ↑"; color = UIColor.systemGreen
        case "declining": arrow = " ↓"; color = UIColor.systemOrange
        default:          arrow = " →"; color = AppColors.primary
        }
        
        let scoreText = "\(Int(score.rounded()))\(arrow)"
        let attr = NSMutableAttributedString(
            string: "\(Int(score.rounded()))",
            attributes: [.foregroundColor: AppColors.textPrimary]
        )
        attr.append(NSAttributedString(
            string: arrow,
            attributes: [.foregroundColor: color, .font: UIFont.systemFont(ofSize: 48, weight: .black)]
        ))
        _ = scoreText  // keep for debugging
        scoreLabel.attributedText = attr
        subtitleLabel.text = summary
    }
    
}
