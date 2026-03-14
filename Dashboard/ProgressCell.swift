import UIKit

// MARK: - Data struct the dashboard passes into the cell

struct ProgressCellData {
    let streakDays: Int
    let todayMinutes: Int
    let dailyGoalMinutes: Int
    let weeklyMinutes: [Int]   // 7 values, Mon → Sun
    /// Optional rolling speech profile from BackendSpeechService
    var speechProfile: UserSpeechProfile? = nil
    /// Optional WPM delta from last session
    var lastWpmDelta: Double? = nil
    /// Optional growth summary from recent scored sessions
    var growthSummary: String? = nil
    /// True only when the user has completed at least one session (jam, roleplay, or call)
    var hasCompletedSessions: Bool = false
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
        b.translatesAutoresizingMaskIntoConstraints = false
        UIHelper.styleSmallCTAButton(b)
        return b
    }()

    // ── Speech Coach Score + Delta ──

    private let coachingScoreLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let lastDeltaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textAlignment = .right
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // MARK: - Bar data cache

    private var barHostViews: [UIView] = []
    private var barBgLayers: [CALayer] = []
    private var barFillLayers: [CALayer] = []
    private var dayLabels: [UILabel] = []
    private var storedBarValues: [Int] = Array(repeating: 0, count: 7)
    private var storedBarMax: Int = 1
    private var currentRingProgress: CGFloat = 0

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
        contentView.addSubview(coachingScoreLabel)
        contentView.addSubview(lastDeltaLabel)
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

            // Greeting — top-right corner
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

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

            // Coaching score — top right, below greeting
            coachingScoreLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 2),
            coachingScoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Delta — below coaching score
            lastDeltaLabel.topAnchor.constraint(equalTo: coachingScoreLabel.bottomAnchor, constant: 1),
            lastDeltaLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
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

    override func prepareForReuse() {
        super.prepareForReuse()
        ringProgressLayer.removeAnimation(forKey: "progressAnimation")
        currentRingProgress = 0
        ringProgressLayer.strokeEnd = 0
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

        ringProgressLayer.strokeEnd = currentRingProgress
    }

    private func animateRingProgress(to target: CGFloat) {
        let clampedTarget = min(max(target, 0), 1)

        // On first configure, Auto Layout may not have finalized ring bounds yet.
        // Ensure layers have a valid path before attempting animation.
        if ringProgressLayer.path == nil {
            setNeedsLayout()
            layoutIfNeeded()
            drawRing()
        }

        let fromValue = ringProgressLayer.presentation()?.strokeEnd ?? ringProgressLayer.strokeEnd

        ringProgressLayer.removeAnimation(forKey: "progressAnimation")

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = fromValue
        animation.toValue = clampedTarget
        animation.duration = 0.55
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        currentRingProgress = clampedTarget
        ringProgressLayer.strokeEnd = clampedTarget
        ringProgressLayer.add(animation, forKey: "progressAnimation")
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
        // Ensure ring container has its final bounds on first load so the path exists.
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        // Streak
        streakCountLabel.text = "\(data.streakDays) day streak"

        // Greeting
        greetingLabel.text = greetingText()

        // Ring
        if data.dailyGoalMinutes <= 0 {
            animateRingProgress(to: 0)
            percentLabel.text = "—"
            goalSubLabel.text = "No schedule"
        } else {
            let pct = min(Double(data.todayMinutes) / Double(data.dailyGoalMinutes), 1.0)
            animateRingProgress(to: CGFloat(pct))
            percentLabel.text = "\(Int(pct * 100))%"

            let remaining = max(0, data.dailyGoalMinutes - data.todayMinutes)
            goalSubLabel.text = "\(remaining) min left"
        }

        // Weekly bars
        let maxMinutes = max(data.weeklyMinutes.max() ?? 0, max(data.dailyGoalMinutes, 1))
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

        // ── Coaching score + delta (only after the user has completed real sessions) ──
        if data.hasCompletedSessions,
           let profile = data.speechProfile,
           profile.sessionsCount > 0 {
            let overall = Int((profile.fluencyScore + profile.confidenceScore + profile.clarityScore) / 3.0)
            coachingScoreLabel.text = "Speech score: \(overall)%"
            coachingScoreLabel.isHidden = false
        } else {
            coachingScoreLabel.isHidden = true
        }

        if data.hasCompletedSessions {
            var lines: [String] = []

            if let summary = data.growthSummary, !summary.isEmpty {
                lines.append(summary)
            }

            if let delta = data.lastWpmDelta, abs(delta) >= 1 {
                let arrow = delta > 0 ? "↑" : "↓"
                lines.append("\(arrow) \(abs(Int(delta))) WPM since last session")
            }

            if !lines.isEmpty {
                lastDeltaLabel.text = lines.joined(separator: "\n")
                lastDeltaLabel.isHidden = false
            } else {
                lastDeltaLabel.isHidden = true
            }
        } else {
            lastDeltaLabel.isHidden = true
            lastDeltaLabel.text = nil
        }

        // For brand-new users, show a welcome hint below the greeting
        if !data.hasCompletedSessions {
            coachingScoreLabel.text = "Start a session to track progress"
            coachingScoreLabel.textColor = .secondaryLabel
            coachingScoreLabel.font = .systemFont(ofSize: 12, weight: .regular)
            coachingScoreLabel.isHidden = false
            lastDeltaLabel.isHidden = true
        } else {
            coachingScoreLabel.textColor = AppColors.primary
            coachingScoreLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        }
    }

    // MARK: - Dynamic colors

    private func applyDynamicColors() {
        backgroundColor = AppColors.cardBackground
        layer.borderColor = AppColors.cardBorder.cgColor

        streakContainer.backgroundColor = AppColors.streakBadgeBackground
        streakCountLabel.textColor = AppColors.streakBadgeText

        greetingLabel.textColor = .secondaryLabel
        coachingScoreLabel.textColor = AppColors.primary
        lastDeltaLabel.textColor = .secondaryLabel
        percentLabel.textColor = AppColors.textPrimary
        goalSubLabel.textColor = .secondaryLabel

        UIHelper.styleSmallCTAButton(seeProgressButton)
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
