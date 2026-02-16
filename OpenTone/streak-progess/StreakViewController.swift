
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

    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!

    @IBOutlet weak var historyButton: UIButton!

    @IBAction func historyButtonTapped(_ sender: UIButton) {
        guard let selectedIndex = selectedWeekdayIndex else { return }
        let selectedDate = dateForWeekday(at: selectedIndex)

        let realSessions = StreakDataModel.shared.sessions(for: selectedDate)
        let sessions: [HistoryItem] = realSessions.map { session in
            // Infer activity type from icon name
            let activityType: ActivityType?
            switch session.iconName {
            case "mic.fill":
                activityType = .jam
            case "person.2.fill", "person.fill":
                activityType = .roleplay
            case "phone.fill":
                activityType = .call
            default:
                activityType = nil
            }

            return HistoryItem(
                title: session.title,
                subtitle: session.subtitle,
                topic: session.topic,
                duration: "\(session.durationMinutes) min",
                xp: "\(session.xp) XP",
                iconName: session.iconName,
                date: session.date,
                activityType: activityType
            )
        }

        guard !sessions.isEmpty else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        if let vc = storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryViewController {
            vc.items = sessions
            vc.selectedDate = selectedDate
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBOutlet weak var bestDayLabel: UILabel!
    @IBOutlet weak var totalWeekTimeLabel: UILabel!
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var weekdaysStackView: UIStackView!

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCloseButton()
        styleHistoryButton()
        centerLabels()
        applyTheme()
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

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true

        loadWeekdayData()
        let todayIndex = mondayBasedWeekdayIndex(from: Date())
        selectedWeekdayIndex = todayIndex

        updateHistoryButtonState()
        animateWeekdays()
        animateBigRing()
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

        percentLabel.textColor = AppColors.textPrimary
        goalLabel.textColor = .secondaryLabel
        comparisonLabel.textColor = .secondaryLabel
        bestDayLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        totalWeekTimeLabel.textColor = .white

    }

    private func styleHistoryButton() {
        UIHelper.styleLargeCTAButton(historyButton, icon: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        historyButton.setTitle("  View History", for: .normal)
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
        let today = Date()
        let date = dateForWeekday(at: index)
        return calendar.compare(date, to: today, toGranularity: .day) != .orderedDescending
    }

    // MARK: - Animations

    func animateBigRing() {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        let progress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
        bigCircularRing.setProgress(min(progress, 1))
        percentLabel.text = "\(Int(min(progress, 1) * 100))%"
    }

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

        let progress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
        bigCircularRing.setProgress(min(progress, 1))
        percentLabel.text = "\(Int(min(progress, 1) * 100))%"

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

        if let bestDay = totalsByDay.max(by: { $0.value < $1.value })?.key, totalsByDay[bestDay]! > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            bestDayLabel.text = "Best day: \(formatter.string(from: bestDay))"
        } else {
            bestDayLabel.text = "No activity yet"
        }
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
        let hasSessions = !StreakDataModel.shared.sessions(for: selectedDate).isEmpty

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
