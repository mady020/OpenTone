import UIKit

// MARK: - Data struct the dashboard passes into the cell

struct ProgressCellData {
    let streakDays: Int
    let todayMinutes: Int
    let dailyGoalMinutes: Int
    let weeklyMinutes: [Int]   // 7 values, Mon → Sun
}

// MARK: - Redesigned Progress Cell (fully programmatic)

final class ProgressCell: UICollectionViewCell {

    static let reuseID = "ProgressCell"

    // MARK: - Callback

    var onSeeProgressTapped: (() -> Void)?

    // MARK: - Subviews

    // ── Top row: Streak badge + greeting ──

    private let streakContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let flameLabel: UILabel = {
        let l = UILabel()
        l.text = "🔥"
        l.font = .systemFont(ofSize: 18)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let streakCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let greetingLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // ── Center: Ring + % + minutes ──

    private let ringContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let ringBackgroundLayer = CAShapeLayer()
    private let ringProgressLayer  = CAShapeLayer()

    private let percentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 26, weight: .heavy)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let goalSubLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // ── Bottom: Weekly mini bars ──

    private let weekStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .bottom
        s.distribution = .fillEqually
        s.spacing = 6
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // ── CTA ──

    private let seeProgressButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("See overall progress", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        b.setTitleColor(AppColors.textOnPrimary, for: .normal)
        b.backgroundColor = AppColors.primary
        b.layer.cornerRadius = 16
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Bar data cache

    private var barHostViews: [UIView] = []
    private var barBgLayers: [CALayer] = []
    private var barFillLayers: [CALayer] = []
    private var dayLabels: [UILabel] = []
    private var storedBarValues: [Int] = Array(repeating: 0, count: 7)
    private var storedBarMax: Int = 1

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Layout

    private let dayAbbreviations = ["M", "T", "W", "T", "F", "S", "S"]

    private func setupUI() {
        // Cell layer: shadow + border (no clipping)
        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false

        // Content view: clips content
        contentView.backgroundColor = AppColors.cardBackground
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        buildWeekBars()

        contentView.addSubview(streakContainer)
        streakContainer.addSubview(flameLabel)
        streakContainer.addSubview(streakCountLabel)
        contentView.addSubview(greetingLabel)
        contentView.addSubview(ringContainer)
        ringContainer.addSubview(percentLabel)
        ringContainer.addSubview(goalSubLabel)
        contentView.addSubview(weekStack)
        contentView.addSubview(seeProgressButton)

        let ringSize: CGFloat = 110

        NSLayoutConstraint.activate([
            // Streak badge
            streakContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            streakContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            streakContainer.heightAnchor.constraint(equalToConstant: 28),

            flameLabel.leadingAnchor.constraint(equalTo: streakContainer.leadingAnchor, constant: 8),
            flameLabel.centerYAnchor.constraint(equalTo: streakContainer.centerYAnchor),

            streakCountLabel.leadingAnchor.constraint(equalTo: flameLabel.trailingAnchor, constant: 2),
            streakCountLabel.trailingAnchor.constraint(equalTo: streakContainer.trailingAnchor, constant: -10),
            streakCountLabel.centerYAnchor.constraint(equalTo: streakContainer.centerYAnchor),

            // Greeting
            greetingLabel.centerYAnchor.constraint(equalTo: streakContainer.centerYAnchor),
            greetingLabel.leadingAnchor.constraint(equalTo: streakContainer.trailingAnchor, constant: 10),
            greetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            // Ring
            ringContainer.topAnchor.constraint(equalTo: streakContainer.bottomAnchor, constant: 12),
            ringContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ringContainer.widthAnchor.constraint(equalToConstant: ringSize),
            ringContainer.heightAnchor.constraint(equalToConstant: ringSize),

            percentLabel.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: ringContainer.centerYAnchor, constant: -8),

            goalSubLabel.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor),
            goalSubLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 0),

            // Weekly bars
            weekStack.leadingAnchor.constraint(equalTo: ringContainer.trailingAnchor, constant: 16),
            weekStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weekStack.centerYAnchor.constraint(equalTo: ringContainer.centerYAnchor, constant: 4),
            weekStack.heightAnchor.constraint(equalToConstant: 70),

            // Button
            seeProgressButton.topAnchor.constraint(equalTo: ringContainer.bottomAnchor, constant: 14),
            seeProgressButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            seeProgressButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            seeProgressButton.heightAnchor.constraint(equalToConstant: 40),
            seeProgressButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),
        ])

        seeProgressButton.addTarget(self, action: #selector(seeProgressTapped), for: .touchUpInside)
        applyDynamicColors()
    }

    // MARK: - Ring drawing

    override func layoutSubviews() {
        super.layoutSubviews()
        drawRing()
        updateBarFrames()
    }

    private func drawRing() {
        let center = CGPoint(x: ringContainer.bounds.midX, y: ringContainer.bounds.midY)
        let radius = min(ringContainer.bounds.width, ringContainer.bounds.height) / 2 - 8
        guard radius > 0 else { return }

        let path = UIBezierPath(
            arcCenter: center, radius: radius,
            startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true
        ).cgPath

        ringBackgroundLayer.path = path
        ringBackgroundLayer.strokeColor = AppColors.ringTrack.cgColor
        ringBackgroundLayer.fillColor = UIColor.clear.cgColor
        ringBackgroundLayer.lineWidth = 14
        ringBackgroundLayer.lineCap = .round

        ringProgressLayer.path = path
        ringProgressLayer.strokeColor = AppColors.primary.cgColor
        ringProgressLayer.fillColor = UIColor.clear.cgColor
        ringProgressLayer.lineWidth = 14
        ringProgressLayer.lineCap = .round

        if ringBackgroundLayer.superlayer == nil {
            ringContainer.layer.insertSublayer(ringBackgroundLayer, at: 0)
        }
        if ringProgressLayer.superlayer == nil {
            ringContainer.layer.insertSublayer(ringProgressLayer, above: ringBackgroundLayer)
        }
    }

    // MARK: - Weekly bars

    private func buildWeekBars() {
        for i in 0..<7 {
            let col = UIView()
            col.translatesAutoresizingMaskIntoConstraints = false

            let barHost = UIView()
            barHost.translatesAutoresizingMaskIntoConstraints = false
            barHost.clipsToBounds = true
            barHost.layer.cornerRadius = 4

            let dayLabel = UILabel()
            dayLabel.text = dayAbbreviations[i]
            dayLabel.font = .systemFont(ofSize: 10, weight: .medium)
            dayLabel.textColor = .secondaryLabel
            dayLabel.textAlignment = .center
            dayLabel.translatesAutoresizingMaskIntoConstraints = false
            dayLabels.append(dayLabel)

            col.addSubview(barHost)
            col.addSubview(dayLabel)

            NSLayoutConstraint.activate([
                barHost.topAnchor.constraint(equalTo: col.topAnchor),
                barHost.centerXAnchor.constraint(equalTo: col.centerXAnchor),
                barHost.widthAnchor.constraint(equalToConstant: 10),
                barHost.bottomAnchor.constraint(equalTo: dayLabel.topAnchor, constant: -3),

                dayLabel.bottomAnchor.constraint(equalTo: col.bottomAnchor),
                dayLabel.centerXAnchor.constraint(equalTo: col.centerXAnchor),
            ])

            weekStack.addArrangedSubview(col)
            barHostViews.append(barHost)

            let bgLayer = CALayer()
            bgLayer.cornerRadius = 4
            barHost.layer.addSublayer(bgLayer)
            barBgLayers.append(bgLayer)

            let fillLayer = CALayer()
            fillLayer.cornerRadius = 4
            barHost.layer.addSublayer(fillLayer)
            barFillLayers.append(fillLayer)
        }
    }

    private func updateBarFrames() {
        for i in 0..<7 {
            let barHost = barHostViews[i]
            let bgLayer = barBgLayers[i]
            let fillLayer = barFillLayers[i]

            let hostH = barHost.bounds.height
            let hostW: CGFloat = 10
            guard hostH > 0 else { continue }

            bgLayer.frame = CGRect(x: 0, y: 0, width: hostW, height: hostH)
            bgLayer.backgroundColor = AppColors.ringTrack.cgColor

            let value = i < storedBarValues.count ? storedBarValues[i] : 0
            let ratio = CGFloat(min(Double(value) / Double(max(storedBarMax, 1)), 1.0))
            let fillH = max(hostH * ratio, ratio > 0 ? 6 : 0)

            fillLayer.frame = CGRect(x: 0, y: hostH - fillH, width: hostW, height: fillH)
            fillLayer.backgroundColor = AppColors.primary.cgColor
        }
    }

    // MARK: - Configure

    func configure(with data: ProgressCellData) {
        // Streak
        streakCountLabel.text = "\(data.streakDays) day streak"

        // Greeting
        greetingLabel.text = greetingText()

        // Ring
        let goalSafe = max(data.dailyGoalMinutes, 1)
        let pct = min(Double(data.todayMinutes) / Double(goalSafe), 1.0)
        ringProgressLayer.strokeEnd = CGFloat(pct)
        percentLabel.text = "\(Int(pct * 100))%"

        let remaining = max(0, data.dailyGoalMinutes - data.todayMinutes)
        goalSubLabel.text = "\(remaining) min left"

        // Weekly bars
        let maxMinutes = max(data.weeklyMinutes.max() ?? 1, data.dailyGoalMinutes)
        storedBarValues = data.weeklyMinutes
        storedBarMax = maxMinutes
        setNeedsLayout()

        // Highlight today
        let todayIdx = mondayBasedWeekdayIndex()
        for (i, lbl) in dayLabels.enumerated() {
            lbl.font = i == todayIdx
                ? .systemFont(ofSize: 10, weight: .bold)
                : .systemFont(ofSize: 10, weight: .medium)
            lbl.textColor = i == todayIdx ? AppColors.primary : .secondaryLabel
        }
    }

    // MARK: - Dynamic colors

    private func applyDynamicColors() {
        backgroundColor = AppColors.cardBackground
        layer.borderColor = AppColors.cardBorder.cgColor

        streakContainer.backgroundColor = AppColors.streakBadgeBackground
        streakCountLabel.textColor = AppColors.streakBadgeText

        greetingLabel.textColor = .secondaryLabel
        percentLabel.textColor = AppColors.textPrimary
        goalSubLabel.textColor = .secondaryLabel

        seeProgressButton.backgroundColor = AppColors.primary
        seeProgressButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyDynamicColors()
            drawRing()
            updateBarFrames()
        }
    }

    // MARK: - Helpers

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning ☀️"
        case 12..<17: return "Good afternoon 🌤️"
        case 17..<21: return "Good evening 🌙"
        default:      return "Keep going 🌟"
        }
    }

    private func mondayBasedWeekdayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    @objc private func seeProgressTapped() {
        onSeeProgressTapped?()
    }
}
