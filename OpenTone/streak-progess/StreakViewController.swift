
import UIKit

struct WeekdayStreak {
    let completed: Int
    let target: Int

    var progress: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(completed) / CGFloat(target)
    }
}

class StreakViewController: UIViewController {

    private enum GrowthRange: Int {
        case sevenDays = 0
        case thirtyDays = 1
        case allTime = 2

        var daysBack: Int? {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .allTime: return nil
            }
        }
    }

    private var comparisonLabel = UILabel()
    private var goalLabel = UILabel()
    private var historyButton = UIButton(type: .system)

    @objc private func historyButtonTapped(_ sender: UIButton) {
        guard let selectedIndex = selectedWeekdayIndex else { return }
        guard isDayEnabled(index: selectedIndex) else { return }
        let selectedDate = dateForWeekday(at: selectedIndex)

        let activities = HistoryDataModel.shared.getActivities(for: selectedDate)
        let sessions: [HistoryItem] = activities.map { activity in
            let iconName: String
            switch activity.type {
            case .jam:
                iconName = "mic.fill"
            case .roleplay:
                iconName = "person.2.fill"
            case .aiCall:
                iconName = "phone.fill"
            }

            let displayDuration = formattedDuration(for: activity)
            return HistoryItem(
                title: activity.title,
                subtitle: activity.type.rawValue,
                topic: activity.topic,
                duration: displayDuration,
                iconName: iconName,
                date: activity.date,
                activityType: activity.type,
                scenarioId: activity.scenarioId,
                isCompleted: activity.isCompleted,
                feedback: activity.feedback
            )
        }

        guard !sessions.isEmpty else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        let vc = HistoryViewController()
        vc.items = sessions
        vc.selectedDate = selectedDate
        navigationController?.pushViewController(vc, animated: true)
    }

    private func formattedDuration(for activity: Activity) -> String {
        // Roleplay duration is stored in seconds in parts of the current pipeline.
        if activity.type == .roleplay, activity.duration > 45 {
            let minutes = max(1, Int(round(Double(activity.duration) / 60.0)))
            return "\(minutes) min"
        }
        return "\(max(1, activity.duration)) min"
    }

    private var bestDayLabel = UILabel()
    private var totalWeekTimeLabel = UILabel()
    private var weekdaysStackView = UIStackView()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()
    private let timeSpentTitleLabel = UILabel()
    private let weeklyInsightsTitleLabel = UILabel()
    private let insightsCardView = UIView()

    private let growthTrendChartView = GrowthTrendChartView()
    private let growthRangeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["7D", "30D", "All"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    private let metricToggleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private var hasSetupGrowthChart = false
    private var hasBuiltProgrammaticLayout = false
    private var selectedGrowthRange: GrowthRange = .sevenDays
    private var selectedGrowthMetrics: Set<GrowthMetric> = Set(GrowthMetric.allCases)
    private var metricButtons: [GrowthMetric: UIButton] = [:]
    private weak var insightsContainerView: UIView?
    private var insightsHeightConstraint: NSLayoutConstraint?
    private var chartTopWithControlsConstraint: NSLayoutConstraint?
    private var chartTopCompactConstraint: NSLayoutConstraint?

    private var dailyGoalMinutes: Int {
        // Try StreakDataModel first, then user model
        let streakGoal = StreakDataModel.shared.getStreak()?.commitment ?? 0
        if streakGoal > 0 { return streakGoal }
        let userGoal = SessionManager.shared.currentUser?.streak?.commitment ?? 0
        if userGoal > 0 {
            // Sync to StreakDataModel so it stays in sync
            if var streak = StreakDataModel.shared.getStreak() {
                streak.commitment = userGoal
                StreakDataModel.shared.updateStreak(streak)
            }
            return userGoal
        }
        return 10  // sensible fallback
    }

    private var hasAnimated = false
    private var weekdayData: [WeekdayStreak] = []
    private var selectedWeekdayIndex: Int?
    private var historyObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgrammaticLayoutIfNeeded()
        setupCloseButton()
        setupCalendarButton()
        styleHistoryButton()
        centerLabels()
        applyTheme()
        setupGrowthChartIfNeeded()

        historyObserver = NotificationCenter.default.addObserver(
            forName: HistoryDataModel.historyDataLoadedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateGrowthChart()
            self?.updateHistoryButtonState()
        }
    }

    deinit {
        if let historyObserver {
            NotificationCenter.default.removeObserver(historyObserver)
        }
    }

    private func setupCloseButton() {
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = AppColors.textSecondary
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupCalendarButton() {
        let calendarButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "calendar")
        config.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.9)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        calendarButton.configuration = config
        calendarButton.addTarget(self, action: #selector(openCalendarTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: calendarButton)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func openCalendarTapped() {
        let vc = CalendarViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateGrowthChart()
        guard !hasAnimated else { return }
        hasAnimated = true

        loadWeekdayData()
        let todayIndex = mondayBasedWeekdayIndex(from: Date())
        selectedWeekdayIndex = todayIndex

        updateHistoryButtonState()
        animateWeekdays()
        updateGoalLabel()
        updateWeeklyInsights()
        updateNavigationDateTitle()
        emphasizeTodayRingAndLabel()
        setupWeekdayRingTaps()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTheme()
        }
    }

    // MARK: - Theming

    private func applyTheme() {
        view.backgroundColor = AppColors.screenBackground

        timeSpentTitleLabel.textColor = AppColors.textPrimary
        goalLabel.textColor = .secondaryLabel
        comparisonLabel.textColor = .secondaryLabel
        insightsCardView.backgroundColor = AppColors.primary
        weeklyInsightsTitleLabel.textColor = .white
        totalWeekTimeLabel.textColor = .white
        growthRangeControl.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        growthRangeControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.95)
        growthRangeControl.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.9)], for: .normal)
        growthRangeControl.setTitleTextAttributes([.foregroundColor: AppColors.primary], for: .selected)
        updateMetricButtonStyles()

    }

    private func styleHistoryButton() {
        UIHelper.styleLargeCTAButton(historyButton, icon: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        historyButton.setTitle("  View History", for: .normal)
        historyButton.addTarget(self, action: #selector(historyButtonTapped(_:)), for: .touchUpInside)
    }

    private func setupProgrammaticLayoutIfNeeded() {
        guard !hasBuiltProgrammaticLayout else { return }
        hasBuiltProgrammaticLayout = true

        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = AppColors.screenBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        let weekdays = makeWeekdaysSection()
        contentStack.addArrangedSubview(weekdays)

        insightsCardView.translatesAutoresizingMaskIntoConstraints = false
        insightsCardView.layer.cornerRadius = 18
        insightsCardView.clipsToBounds = true
        insightsHeightConstraint = insightsCardView.heightAnchor.constraint(equalToConstant: 110)
        insightsHeightConstraint?.isActive = true
        contentStack.addArrangedSubview(insightsCardView)

        weeklyInsightsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        weeklyInsightsTitleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        weeklyInsightsTitleLabel.text = "Weekly Insights"
        weeklyInsightsTitleLabel.numberOfLines = 1
        insightsCardView.addSubview(weeklyInsightsTitleLabel)

        let bestDay = UILabel()
        bestDay.translatesAutoresizingMaskIntoConstraints = false
        bestDay.font = .systemFont(ofSize: 14, weight: .regular)
        bestDay.numberOfLines = 1
        bestDay.lineBreakMode = .byTruncatingTail
        bestDayLabel = bestDay

        let totalWeek = UILabel()
        totalWeek.translatesAutoresizingMaskIntoConstraints = false
        totalWeek.font = .systemFont(ofSize: 14, weight: .regular)
        totalWeek.numberOfLines = 1
        totalWeek.lineBreakMode = .byTruncatingTail
        totalWeekTimeLabel = totalWeek
        insightsCardView.addSubview(totalWeek)

        NSLayoutConstraint.activate([
            weeklyInsightsTitleLabel.topAnchor.constraint(equalTo: insightsCardView.topAnchor, constant: 16),
            weeklyInsightsTitleLabel.leadingAnchor.constraint(equalTo: insightsCardView.leadingAnchor, constant: 20),
            weeklyInsightsTitleLabel.trailingAnchor.constraint(equalTo: insightsCardView.trailingAnchor, constant: -20),

            totalWeek.topAnchor.constraint(equalTo: weeklyInsightsTitleLabel.bottomAnchor, constant: 10),
            totalWeek.leadingAnchor.constraint(equalTo: insightsCardView.leadingAnchor, constant: 20),
            totalWeek.trailingAnchor.constraint(equalTo: insightsCardView.trailingAnchor, constant: -20)
        ])

        timeSpentTitleLabel.text = "Time Spent Communicating"
        timeSpentTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        timeSpentTitleLabel.textAlignment = .center
        timeSpentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(timeSpentTitleLabel)

        let goal = UILabel()
        goal.font = .systemFont(ofSize: 14, weight: .medium)
        goal.textAlignment = .center
        goal.translatesAutoresizingMaskIntoConstraints = false
        goalLabel = goal
        contentStack.addArrangedSubview(goal)

        let comparison = UILabel()
        comparison.font = .systemFont(ofSize: 13, weight: .medium)
        comparison.textAlignment = .center
        comparison.translatesAutoresizingMaskIntoConstraints = false
        comparisonLabel = comparison
        contentStack.addArrangedSubview(comparison)

        let history = UIButton(type: .system)
        history.translatesAutoresizingMaskIntoConstraints = false
        history.heightAnchor.constraint(equalToConstant: 52).isActive = true
        historyButton = history
        contentStack.addArrangedSubview(history)
    }

    private func makeWeekdaysSection() -> UIStackView {
        let root = UIStackView()
        root.axis = .horizontal
        root.alignment = .top
        root.distribution = .fillEqually
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        root.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let symbols = ["M", "T", "W", "T", "F", "S", "S"]
        for symbol in symbols {
            let dayStack = UIStackView()
            dayStack.axis = .vertical
            dayStack.alignment = .center
            dayStack.spacing = 6
            dayStack.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = symbol
            label.font = .systemFont(ofSize: 12, weight: .medium)

            let ring = WeekdayRingView()
            ring.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                ring.widthAnchor.constraint(equalToConstant: 36),
                ring.heightAnchor.constraint(equalToConstant: 36)
            ])

            dayStack.addArrangedSubview(label)
            dayStack.addArrangedSubview(ring)
            root.addArrangedSubview(dayStack)
        }

        weekdaysStackView = root
        return root
    }

    private func setupGrowthChartIfNeeded() {
        guard !hasSetupGrowthChart else { return }
        let insightsContainer = insightsCardView
        hasSetupGrowthChart = true
        insightsContainerView = insightsContainer

        growthRangeControl.addTarget(self, action: #selector(growthRangeChanged(_:)), for: .valueChanged)

        GrowthMetric.allCases.forEach { metric in
            let button = makeMetricToggleButton(for: metric)
            metricButtons[metric] = button
            metricToggleStack.addArrangedSubview(button)
        }

        updateMetricButtonStyles()

        insightsContainer.addSubview(growthRangeControl)
        insightsContainer.addSubview(metricToggleStack)
        growthTrendChartView.translatesAutoresizingMaskIntoConstraints = false
        insightsContainer.addSubview(growthTrendChartView)

        chartTopWithControlsConstraint = growthTrendChartView.topAnchor.constraint(equalTo: metricToggleStack.bottomAnchor, constant: 8)
        chartTopCompactConstraint = growthTrendChartView.topAnchor.constraint(equalTo: totalWeekTimeLabel.bottomAnchor, constant: 12)
        chartTopWithControlsConstraint?.isActive = true

        NSLayoutConstraint.activate([
            growthRangeControl.leadingAnchor.constraint(equalTo: insightsContainer.leadingAnchor, constant: 14),
            growthRangeControl.trailingAnchor.constraint(equalTo: insightsContainer.trailingAnchor, constant: -14),
            growthRangeControl.topAnchor.constraint(equalTo: totalWeekTimeLabel.bottomAnchor, constant: 8),

            metricToggleStack.leadingAnchor.constraint(equalTo: insightsContainer.leadingAnchor, constant: 14),
            metricToggleStack.trailingAnchor.constraint(equalTo: insightsContainer.trailingAnchor, constant: -14),
            metricToggleStack.topAnchor.constraint(equalTo: growthRangeControl.bottomAnchor, constant: 8),
            metricToggleStack.heightAnchor.constraint(equalToConstant: 28),

            growthTrendChartView.leadingAnchor.constraint(equalTo: insightsContainer.leadingAnchor, constant: 14),
            growthTrendChartView.trailingAnchor.constraint(equalTo: insightsContainer.trailingAnchor, constant: -14),
            growthTrendChartView.bottomAnchor.constraint(equalTo: insightsContainer.bottomAnchor, constant: -12),
            growthTrendChartView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ])
    }

    private func updateGrowthChart() {
        let trendPoints = HistoryDataModel.shared.feedbackTrendPoints(
            daysBack: selectedGrowthRange.daysBack,
            limit: 120,
            smoothingWindow: 3
        )

        let hasEnoughTrendData = trendPoints.count >= 2
        growthRangeControl.isHidden = !hasEnoughTrendData
        metricToggleStack.isHidden = !hasEnoughTrendData
        chartTopWithControlsConstraint?.isActive = hasEnoughTrendData
        chartTopCompactConstraint?.isActive = !hasEnoughTrendData

        insightsHeightConstraint?.constant = hasEnoughTrendData ? 244 : 156
        insightsContainerView?.layoutIfNeeded()

        growthTrendChartView.configure(with: trendPoints, visibleMetrics: selectedGrowthMetrics)
    }

    @objc private func growthRangeChanged(_ sender: UISegmentedControl) {
        selectedGrowthRange = GrowthRange(rawValue: sender.selectedSegmentIndex) ?? .sevenDays
        updateGrowthChart()
    }

    private func makeMetricToggleButton(for metric: GrowthMetric) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = metric.rawValue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(metric.title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(metricToggleTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func metricToggleTapped(_ sender: UIButton) {
        guard let metric = GrowthMetric(rawValue: sender.tag) else { return }

        if selectedGrowthMetrics.contains(metric) {
            // Keep at least one metric selected.
            guard selectedGrowthMetrics.count > 1 else { return }
            selectedGrowthMetrics.remove(metric)
        } else {
            selectedGrowthMetrics.insert(metric)
        }

        updateMetricButtonStyles()
        updateGrowthChart()
    }

    private func updateMetricButtonStyles() {
        metricButtons.forEach { metric, button in
            let isSelected = selectedGrowthMetrics.contains(metric)
            if isSelected {
                button.backgroundColor = metric.color
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = metric.color.cgColor
                button.alpha = 1.0
            } else {
                button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
                button.setTitleColor(UIColor.white.withAlphaComponent(0.9), for: .normal)
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
                button.alpha = 1.0
            }
        }
    }

    private func centerLabels() {
        goalLabel.textAlignment = .center
        comparisonLabel.textAlignment = .center
    }

    // MARK: - Data

    func loadWeekdayData() {
        weekdayData = []
        for index in 0..<7 {
            let date = dateForWeekday(at: index)
            let totalMinutes = StreakDataModel.shared.totalMinutes(for: date)
            weekdayData.append(WeekdayStreak(completed: totalMinutes, target: dailyGoalMinutes))
        }
    }

    func mondayBasedWeekdayIndex(from date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    func dateForWeekday(at index: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayIndex = mondayBasedWeekdayIndex(from: today)
        let diff = index - todayIndex
        return calendar.date(byAdding: .day, value: diff, to: today) ?? today
    }

    func isDayEnabled(index: Int) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: dateForWeekday(at: index))

        // If createdAt is unavailable (e.g. local temp user), default to today only.
        let createdStart = SessionManager.shared.currentUser?.createdAt
            .map { calendar.startOfDay(for: $0) }
            ?? todayStart

        let isNotFuture = dayStart <= todayStart
        let isAfterAccountCreation = dayStart >= createdStart
        return isNotFuture && isAfterAccountCreation
    }

    // MARK: - Animations

    func animateWeekdays() {
        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {
            guard index < weekdayData.count,
                  let dayStack = view as? UIStackView,
                  let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            let date = dateForWeekday(at: index)
            let todayMinutes = StreakDataModel.shared.totalMinutes(for: date)
            let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            let yesterdayMinutes = StreakDataModel.shared.totalMinutes(for: yesterdayDate)

            let todayProgress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
            let yesterdayProgress = CGFloat(yesterdayMinutes) / CGFloat(dailyGoalMinutes)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                ringView.animate(progress: min(todayProgress, 1), yesterdayProgress: min(yesterdayProgress, 1))
            }
            ringView.alpha = isDayEnabled(index: index) ? 1.0 : 0.3
        }
    }

    // MARK: - Tap handling

    func setupWeekdayRingTaps() {
        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {
            guard let dayStack = view as? UIStackView,
                  let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            ringView.onTap = { [weak self] in
                guard let self = self, self.isDayEnabled(index: index) else { return }
                self.selectedWeekdayIndex = index
                self.refreshWeekdayEmphasis()
                self.showProgressForDay(at: index)
            }
        }
    }

    func showProgressForDay(at index: Int) {
        guard index < weekdayData.count else { return }
        let date = dateForWeekday(at: index)

        let todayMinutes = StreakDataModel.shared.totalMinutes(for: date)
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        let previousMinutes = StreakDataModel.shared.totalMinutes(for: previousDate)

        goalLabel.text = "\(todayMinutes) min / \(dailyGoalMinutes) min goal"

        let diffMinutes = todayMinutes - previousMinutes
        if diffMinutes == 0 {
            comparisonLabel.text = "Same as yesterday"
        } else {
            let sign = diffMinutes > 0 ? "+" : "-"
            comparisonLabel.text = "\(sign)\(abs(diffMinutes)) min from yesterday"
        }

        updateWeeklyInsights(for: date)
        updateNavigationDateTitle(for: date)
        updateHistoryButtonState()
    }

    // MARK: - Labels

    private func formatTime(_ minutes: Int) -> String {
        return "\(minutes) min"
    }

    func updateGoalLabel() {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        goalLabel.text = "\(todayMinutes) min / \(dailyGoalMinutes) min goal"

        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let previousMinutes = StreakDataModel.shared.totalMinutes(for: previousDate)
        let diffMinutes = todayMinutes - previousMinutes
        if diffMinutes == 0 {
            comparisonLabel.text = "Same as yesterday"
        } else {
            let sign = diffMinutes > 0 ? "+" : "-"
            comparisonLabel.text = "\(sign)\(abs(diffMinutes)) min from yesterday"
        }
    }

    func updateWeeklyInsights(for selectedDate: Date? = nil) {
        let calendar = Calendar.current
        let referenceDate = selectedDate ?? Date()
        var totalsByDay: [Date: Int] = [:]

        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: -i, to: referenceDate) {
                let startOfDay = calendar.startOfDay(for: day)
                totalsByDay[startOfDay] = StreakDataModel.shared.totalMinutes(for: day)
            }
        }

        let totalWeekMinutes = totalsByDay.values.reduce(0, +)
        totalWeekTimeLabel.text = String(format: "This week: %.1fh", Double(totalWeekMinutes) / 60)
    }

    func updateNavigationDateTitle(for date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        navigationItem.title = formatter.string(from: date)
    }

    // MARK: - Ring emphasis

    func emphasizeTodayRingAndLabel() {
        let todayIndex = mondayBasedWeekdayIndex(from: Date())
        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {
            guard let dayStack = view as? UIStackView,
                  let dayLabel = dayStack.arrangedSubviews.first as? UILabel,
                  let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            let enabled = isDayEnabled(index: index)
            let isToday = index == todayIndex

            ringView.setEmphasis(isToday: isToday && enabled)
            ringView.alpha = enabled ? 1.0 : 0.3
            dayLabel.alpha = enabled ? 1.0 : 0.3
            dayLabel.textColor = AppColors.textPrimary
            dayLabel.font = .systemFont(ofSize: dayLabel.font.pointSize, weight: isToday ? .semibold : .regular)
        }
    }

    func refreshWeekdayEmphasis() {
        let todayIndex = mondayBasedWeekdayIndex(from: Date())
        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {
            guard let dayStack = view as? UIStackView,
                  let dayLabel = dayStack.arrangedSubviews.first as? UILabel,
                  let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            let enabled = isDayEnabled(index: index)
            let isToday = index == todayIndex
            let isSelected = index == selectedWeekdayIndex

            ringView.setEmphasis(isToday: isToday && enabled, isSelected: isSelected && enabled)
            ringView.alpha = enabled ? 1.0 : 0.3
            dayLabel.alpha = enabled ? 1.0 : 0.3
            dayLabel.textColor = AppColors.textPrimary
            dayLabel.font = .systemFont(ofSize: dayLabel.font.pointSize, weight: (isToday || isSelected) ? .semibold : .regular)
        }
    }

    // MARK: - History button

    private func updateHistoryButtonState() {
        guard let selectedIndex = selectedWeekdayIndex else {
            applyHistoryDisabledStyle()
            return
        }

        let selectedDate = dateForWeekday(at: selectedIndex)
        let hasSessions = !HistoryDataModel.shared.getActivities(for: selectedDate).isEmpty

        hasSessions ? applyHistoryEnabledStyle() : applyHistoryDisabledStyle()
    }

    private func applyHistoryDisabledStyle() {
        historyButton.isEnabled = false
        historyButton.alpha = 0.5
    }

    private func applyHistoryEnabledStyle() {
        historyButton.isEnabled = true
        historyButton.alpha = 1.0
    }
}
