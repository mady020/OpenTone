import UIKit

class ProgressHeaderView: UIView {

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Your Progress"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = AppColors.textPrimary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Lifetime averages"
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Stats area
    private let statsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var statsTopConstraint: NSLayoutConstraint?
    private var statsBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(statsStack)

        statsTopConstraint = statsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24)
        statsBottomConstraint = statsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            statsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statsTopConstraint!,
            statsBottomConstraint!
        ])

        // Default to compact layout until stats are loaded.
        setShowsStats(false)
    }

    func configure(with profile: UserSpeechProfile) {
        // Clear old ones
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Create Stat Cards
        let wpmCard = createStatCard(title: "WPM", value: String(format: "%.0f", profile.avgWpm))
        let fluCard = createStatCard(title: "Fluency", value: String(format: "%.0f", profile.overallScore))
        let filCard = createStatCard(title: "Fillers", value: String(format: "%.1f/m", profile.avgFillerRate))

        statsStack.addArrangedSubview(wpmCard)
        statsStack.addArrangedSubview(fluCard)
        statsStack.addArrangedSubview(filCard)

        setShowsStats(true)
    }

    func clearStats() {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        setShowsStats(false)
    }

    func requiredHeight(for width: CGFloat) -> CGFloat {
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let size = systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return ceil(size.height)
    }

    private func setShowsStats(_ show: Bool) {
        statsStack.isHidden = !show
        statsTopConstraint?.constant = show ? 24 : 0
        statsBottomConstraint?.constant = show ? -20 : -8
    }

    private func createStatCard(title: String, value: String) -> UIView {
        let v = UIView()
        v.backgroundColor = AppColors.cardBackground
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = AppColors.cardBorder.cgColor

        let valLbl = UILabel()
        valLbl.text = value
        valLbl.font = .systemFont(ofSize: 20, weight: .bold)
        valLbl.textColor = AppColors.primary
        valLbl.textAlignment = .center
        valLbl.translatesAutoresizingMaskIntoConstraints = false

        let titLbl = UILabel()
        titLbl.text = title
        titLbl.font = .systemFont(ofSize: 12, weight: .medium)
        titLbl.textColor = .secondaryLabel
        titLbl.textAlignment = .center
        titLbl.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(valLbl)
        v.addSubview(titLbl)

        NSLayoutConstraint.activate([
            valLbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            valLbl.centerYAnchor.constraint(equalTo: v.centerYAnchor, constant: -8),

            titLbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            titLbl.topAnchor.constraint(equalTo: valLbl.bottomAnchor, constant: 4),
            v.heightAnchor.constraint(equalToConstant: 72)
        ])

        return v
    }
}
