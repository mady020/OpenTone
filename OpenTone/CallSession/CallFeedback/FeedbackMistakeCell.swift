import UIKit

/// Section 3 — Biggest Issue  + Section 4 — Evidence
/// Shows the primary issue banner and a list of timestamp evidence rows.
class FeedbackMistakeCell: UICollectionViewCell {

    static let reuseID = "FeedbackMistakeCell"

    private let issueBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        return v
    }()

    private let issueEmoji: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22)
        return l
    }()

    private let issueTitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.numberOfLines = 2
        return l
    }()

    private let sectionHeader: UILabel = {
        let l = UILabel()
        l.text = "EVIDENCE"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let evidenceStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        return v
    }()

    private let outerStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        // Badge row
        let badgeRow = UIStackView(arrangedSubviews: [issueEmoji, issueTitle])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 10
        badgeRow.alignment = .center
        issueBadge.addSubview(badgeRow)
        badgeRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeRow.topAnchor.constraint(equalTo: issueBadge.topAnchor, constant: 12),
            badgeRow.leadingAnchor.constraint(equalTo: issueBadge.leadingAnchor, constant: 14),
            badgeRow.trailingAnchor.constraint(equalTo: issueBadge.trailingAnchor, constant: -14),
            badgeRow.bottomAnchor.constraint(equalTo: issueBadge.bottomAnchor, constant: -12),
        ])

        outerStack.axis = .vertical
        outerStack.spacing = 16
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addArrangedSubview(issueBadge)
        outerStack.addArrangedSubview(sectionHeader)
        outerStack.addArrangedSubview(evidenceStack)
        card.addSubview(outerStack)

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
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackMistakeCell, _) in self.applyStyle() }
    }

    private func applyStyle() {
        card.backgroundColor = AppColors.cardBackground
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.cardBorder.cgColor
    }

    // MARK: - Configure

    func configure(original: String, correction: String, explanation: String) {
        // Legacy shim — not used in new flow
        issueTitle.text = original
        issueEmoji.text = "🔴"
        issueBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.10)
        issueTitle.textColor = UIColor.systemRed
        sectionHeader.isHidden = true
    }

    func configureCoaching(issueTitle: String, evidence: [EvidenceItem]) {
        self.issueTitle.text = issueTitle
        issueEmoji.text = evidence.isEmpty ? "✅" : "🔴"
        let hasIssue = !evidence.isEmpty && issueTitle != "Good Delivery"
        issueBadge.backgroundColor = hasIssue
            ? UIColor.systemRed.withAlphaComponent(0.10)
            : UIColor.systemGreen.withAlphaComponent(0.10)
        self.issueTitle.textColor = hasIssue ? UIColor.systemRed : UIColor.systemGreen
        sectionHeader.isHidden = evidence.isEmpty

        evidenceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        evidence.prefix(6).forEach { evidenceStack.addArrangedSubview(makeEvidenceRow($0)) }
    }

    private func makeEvidenceRow(_ item: EvidenceItem) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center

        let dot = UIView()
        dot.backgroundColor = item.type == "filler" ? AppColors.primary : UIColor.systemOrange
        dot.layer.cornerRadius = 4
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let lbl = UILabel()
        lbl.text = item.text
        lbl.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        lbl.textColor = AppColors.textPrimary

        row.addArrangedSubview(dot)
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(UIView()) // spacer

        let wrapper = UIView()
        wrapper.heightAnchor.constraint(equalToConstant: 36).isActive = true
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
