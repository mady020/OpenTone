//
//  StreakViewController.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

import UIKit

struct WeekdayStreak {
    let completed: Int
    let target: Int

    var progress: CGFloat {
        return CGFloat(completed) / CGFloat(target)
    }
}

class StreakViewController: UIViewController {
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    
    @IBAction func historyButtonTapped(_ sender: UIButton) {
       // let storyboard = UIStoryboard(name: "streak-progess", bundle: nil)
        print("History tapped")   // IMPORTANT → test this first!

        let vc = storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBOutlet weak var bestDayLabel: UILabel!
    @IBOutlet weak var totalWeekTimeLabel: UILabel!
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var weekdaysStackView: UIStackView!
    
    private let dailyGoalMinutes = 420   // 7 hours
    private var hasAnimated = false
    private var weekdayData: [WeekdayStreak] = []
    private var selectedWeekdayIndex: Int?

    var historyItemsArray: [HistoryItem] = [
        HistoryItem(
            title: "2 Min Session",
            subtitle: "You completed 2 min session",
            topic: "Time Travel",
            duration: "2 min",
            xp: "15 XP",
            iconName: "mic.fill"
        ),
        HistoryItem(
            title: "RolePlays",
            subtitle: "You completed RolePlays session",
            topic: "Time Travel",
            duration: "15 min",
            xp: "15 XP",
            iconName: "theatermasks.fill"
        ),
        HistoryItem(
            title: "1 to 1 Call",
            subtitle: "You completed 1 to 1 call session",
            topic: "—",
            duration: "10 min",
            xp: "15 XP",
            iconName: "phone.fill"
        )

    ]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimated else { return }
        hasAnimated = true

        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        selectedWeekdayIndex = todayIndex
        refreshWeekdayEmphasis()
 
        loadWeekdayData()
        animateWeekdays()
        animateBigRing()
        updateGoalLabel()
        updateYesterdayComparisonLabel()
        updateWeeklyInsights()
        updateNavigationDateTitle()
        emphasizeTodayRingAndLabel()
        setupWeekdayRingTaps()

    }

    
    func animateBigRing() {

        let totalCompleted = weekdayData.reduce(0) { $0 + $1.completed }
        let totalTarget = weekdayData.reduce(0) { $0 + $1.target }

        guard totalTarget > 0 else {
            bigCircularRing.setProgress(0)
            percentLabel.text = "0%"
            return
        }

        let rawProgress = CGFloat(totalCompleted) / CGFloat(totalTarget)
        let safeProgress = min(max(rawProgress, 0), 1)   

        bigCircularRing.setProgress(safeProgress)
        percentLabel.text = "\(Int(safeProgress * 100))%"
    }

    func animateWeekdays() {

        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

            guard index < weekdayData.count else { return }

            let dayStack = view as! UIStackView
            let ringView = dayStack.arrangedSubviews[1] as! WeekdayRingView

            let rawProgress = weekdayData[index].progress
            let progress = min(max(rawProgress, 0), 1)  

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                ringView.animate(progress: progress)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHistorySegue" {
            if let dest = segue.destination as? HistoryViewController {
                dest.items = self.historyItemsArray   // your real data
            }
        }
    }
    func loadWeekdayData() {

        // Read from SessionProgressManager
        let manager = SessionProgressManager.shared
        let completedCount = manager.completedSessions.count
        let todayProgress = completedCount
        let target = 3   // total sessions per day

        // Prepare empty week
        weekdayData = Array(
            repeating: WeekdayStreak(completed: 0, target: target),
            count: 7
        )

        // Put progress only on TODAY
        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1

        weekdayData[todayIndex] = WeekdayStreak(
            completed: todayProgress,
            target: target
        )
    }

    func updateGoalLabel() {

        let completedMinutes =
            SessionProgressManager.shared.totalMinutesCompleted()

        let completedHours = Double(completedMinutes) / 60
        let goalHours = Double(dailyGoalMinutes) / 60

        goalLabel.text =
            String(format: "%.1fh / %.0fh goal", completedHours, goalHours)
    }
    func updateYesterdayComparisonLabel() {

        let todayMinutes =
            SessionProgressManager.shared.totalMinutesCompleted()

        guard let yesterday =
            StreakDataModel.shared.loadYesterdayProgress()
        else {
            comparisonLabel.text = "No data from yesterday"
            return
        }

        let diffMinutes = todayMinutes - yesterday.minutesCompleted
        let diffHours = Double(abs(diffMinutes)) / 60

        if diffMinutes >= 0 {
            comparisonLabel.text =
                String(format: "+%.1fh from yesterday", diffHours)
        } else {
            comparisonLabel.text =
                String(format: "-%.1fh from yesterday", diffHours)
        }
    }
    func updateWeeklyInsights() {

        let manager = SessionProgressManager.shared

        var minutesPerDay: [Int: Int] = [:]

        for session in manager.completedSessions {

            let weekday =
                Calendar.current.component(.weekday, from: Date())

            minutesPerDay[weekday, default: 0] += session.durationInMinutes
        }

        // Total time this week
        let totalMinutes = minutesPerDay.values.reduce(0, +)
        let totalHours = Double(totalMinutes) / 60

        totalWeekTimeLabel.text =
            String(format: "This week: %.1fh", totalHours)

        // Best day
        if let best = minutesPerDay.max(by: { $0.value < $1.value }) {

            let dayName = Calendar.current.weekdaySymbols[best.key - 1]
            bestDayLabel.text = "Best day: \(dayName)"

        } else {
            bestDayLabel.text = "Best day: —"
        }
    }
    func updateNavigationDateTitle(for date: Date = Date()) {

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        navigationItem.title = formatter.string(from: date)
    }

    func emphasizeTodayRingAndLabel() {

        let todayIndex =
            Calendar.current.component(.weekday, from: Date()) - 1
        // Sunday = 0

        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

            guard
                let dayStack = view as? UIStackView,
                let dayLabel = dayStack.arrangedSubviews.first as? UILabel,
                let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            let isToday = index == todayIndex

            // Ring emphasis (size + thickness)
            ringView.setEmphasis(isToday: isToday)

            // Label emphasis (bold)
            dayLabel.font = isToday
                ? UIFont.systemFont(ofSize: dayLabel.font.pointSize, weight: .semibold)
                : UIFont.systemFont(ofSize: dayLabel.font.pointSize, weight: .regular)
        }
    }
    
    func setupWeekdayRingTaps() {

        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

            guard
                let dayStack = view as? UIStackView,
                let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            ringView.onTap = { [weak self] in
                self?.showProgressForDay(at: index)
                ringView.onTap = { [weak self] in
                    guard let self = self else { return }

                    self.selectedWeekdayIndex = index
                    self.refreshWeekdayEmphasis()
                    self.showProgressForDay(at: index)
                }

            }
        }
    }
    func showProgressForDay(at index: Int) {

        guard index < weekdayData.count else { return }

        // Update BIG RING
        let dayData = weekdayData[index]

        if dayData.target > 0 {
            let progress =
                CGFloat(dayData.completed) / CGFloat(dayData.target)
            let safeProgress = min(max(progress, 0), 1)

            bigCircularRing.setProgress(safeProgress)
            percentLabel.text = "\(Int(safeProgress * 100))%"
        } else {
            bigCircularRing.setProgress(0)
            percentLabel.text = "0%"
        }

        // UPDATE NAVIGATION DATE
        let selectedDate = dateForWeekday(at: index)
        updateNavigationDateTitle(for: selectedDate)

    }

    func dateForWeekday(at index: Int) -> Date {

        let calendar = Calendar.current
        let today = Date()

        let todayWeekday = calendar.component(.weekday, from: today) - 1
        // Sunday = 0

        let diff = index - todayWeekday

        return calendar.date(byAdding: .day, value: diff, to: today) ?? today
    }
    
    func refreshWeekdayEmphasis() {

        let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1

        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

            guard
                let dayStack = view as? UIStackView,
                let dayLabel = dayStack.arrangedSubviews.first as? UILabel,
                let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }

            let isToday = index == todayIndex
            let isSelected = index == selectedWeekdayIndex

            // Ring emphasis
            ringView.setEmphasis(isToday: isToday, isSelected: isSelected)

            // Label bold
            dayLabel.font = (isToday || isSelected)
                ? UIFont.systemFont(ofSize: dayLabel.font.pointSize, weight: .semibold)
                : UIFont.systemFont(ofSize: dayLabel.font.pointSize, weight: .regular)
        }
    }

}
