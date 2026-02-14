
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
        let sessions: [HistoryItem] = realSessions.map {
            HistoryItem(
                title: $0.title,
                subtitle: $0.subtitle,
                topic: $0.topic,
                duration: "\($0.durationMinutes) min",
                xp: "\($0.xp) XP",
                iconName: $0.iconName
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
        let goal = StreakDataModel.shared.getStreak()?.commitment ?? 0
        return goal > 0 ? goal : 10  // sensible fallback
    }

    private var hasAnimated = false
    private var weekdayData: [WeekdayStreak] = []
    private var selectedWeekdayIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
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
        bestDayLabel.textColor = .secondaryLabel
        totalWeekTimeLabel.textColor = AppColors.textPrimary

        historyButton.setTitleColor(AppColors.primary, for: .normal)
        historyButton.setTitleColor(AppColors.primary.withAlphaComponent(0.4), for: .disabled)
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

        let completedHours = Double(todayMinutes) / 60
        let goalHours = Double(dailyGoalMinutes) / 60
        goalLabel.text = String(format: "%.1fh / %.0fh goal", completedHours, goalHours)

        let diffMinutes = todayMinutes - previousMinutes
        let diffHours = Double(abs(diffMinutes)) / 60
        if diffMinutes == 0 {
            comparisonLabel.text = "Same as yesterday"
        } else {
            comparisonLabel.text = String(format: "%@%.1fh from yesterday", diffMinutes > 0 ? "+" : "-", diffHours)
        }

        updateWeeklyInsights(for: date)
        updateNavigationDateTitle(for: date)
        updateHistoryButtonState()
    }

    // MARK: - Labels

    func updateGoalLabel() {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        let completedHours = Double(todayMinutes) / 60
        let goalHours = Double(dailyGoalMinutes) / 60
        goalLabel.text = String(format: "%.1fh / %.0fh goal", completedHours, goalHours)
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
        historyButton.alpha = 0.45
        historyButton.setTitleColor(AppColors.primary.withAlphaComponent(0.4), for: .normal)
    }

    private func applyHistoryEnabledStyle() {
        historyButton.isEnabled = true
        historyButton.alpha = 1.0
        historyButton.setTitleColor(AppColors.primary, for: .normal)
    }
}
