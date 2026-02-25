import UIKit

/// Section 2 — What Changed
/// Shows delta rows: "+8 WPM (faster)", "2.3 fewer fillers/min", etc.
class FeedbackMetricsCell: UICollectionViewCell {

    static let reuseID = "FeedbackMetricsCell"

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let outerStack = UIStackView(arrangedSubviews: [headerLabel, stack])
        outerStack.axis = .vertical
        outerStack.spacing = 14
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(outerStack)
        // Apply letter spacing after view is created
        headerLabel.attributedText = NSAttributedString(
            string: "WHAT CHANGED",
            attributes: [.kern: 1.2, .foregroundColor: UIColor.tertiaryLabel,
                         .font: UIFont.systemFont(ofSize: 12, weight: .semibold)])

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            outerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            outerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            outerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            outerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])

        applyStyle()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackMetricsCell, _) in self.applyStyle() }
    }

    private func applyStyle() {
        card.backgroundColor = AppColors.cardBackground
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.cardBorder.cgColor
    }

    // MARK: - Configure

    /// Call with an array of (icon, text, isPositive) tuples.
    func configure(rows: [(icon: String, text: String, positive: Bool)]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rows.forEach { stack.addArrangedSubview(makeDeltaRow(icon: $0.icon, text: $0.text, positive: $0.positive)) }
    }

    private func makeDeltaRow(icon: String, text: String, positive: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = positive ? .systemGreen : .systemOrange
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 18).isActive = true
        img.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = AppColors.textPrimary
        lbl.numberOfLines = 2

        let wrapper = UIView()
        wrapper.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        row.addArrangedSubview(img)
        row.addArrangedSubview(lbl)
        wrapper.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            row.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
        ])
        return wrapper
    }
}
