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
          guard target > 0 else { return 0 }
          return CGFloat(completed) / CGFloat(target)
      }
  }

class StreakViewController: UIViewController {
    
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    
    @IBAction func historyButtonTapped(_ sender: UIButton) {
        
        guard let selectedIndex = selectedWeekdayIndex else { return }
        
        let selectedDate = dateForWeekday(at: selectedIndex)
        
        let sessions =
        StreakDataModel.shared.sessions(for: selectedDate)
        
        let items = sessions.map {
            HistoryItem(
                title: $0.title,
                subtitle: $0.subtitle,
                topic: $0.topic,
                duration: "\($0.durationMinutes) min",
                xp: "\($0.xp) XP",
                iconName: $0.iconName
            )
        }
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "HistoryViewController"
        ) as! HistoryViewController
        
        vc.items = items
        vc.selectedDate = selectedDate
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBOutlet weak var bestDayLabel: UILabel!
    @IBOutlet weak var totalWeekTimeLabel: UILabel!
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var weekdaysStackView: UIStackView!
    
    // Properties
    private let dailyGoalMinutes = 420   // 7 hours
    private var hasAnimated = false
    private var weekdayData: [WeekdayStreak] = []
    private var selectedWeekdayIndex: Int?
    
    private var historyByDate: [Date: [HistoryItem]] = [:]
    
    
    // USER JOINED YESTERDAY
    private let joinDate: Date = Calendar.current.date(
        byAdding: .day,
        value: -1,
        to: Date()
    )!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true
        
        loadWeekdayData()
        let todayIndex = mondayBasedWeekdayIndex(from: Date())
        selectedWeekdayIndex = todayIndex
        
        animateWeekdays()
        animateBigRing()
        updateGoalLabel()
        updateWeeklyInsights()
        updateNavigationDateTitle()
        emphasizeTodayRingAndLabel()
        setupWeekdayRingTaps()
    }
    
    // Weekday Data
    func loadWeekdayData() {
        weekdayData = []
        for index in 0..<7 {
            let date = dateForWeekday(at: index)
            let totalMinutes = StreakDataModel.shared.totalMinutes(for: date)
            let progressValue = min(CGFloat(totalMinutes) / CGFloat(dailyGoalMinutes), 1.0)
            weekdayData.append(WeekdayStreak(completed: Int(progressValue * CGFloat(dailyGoalMinutes)), target: dailyGoalMinutes))
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
        if calendar.compare(date, to: today, toGranularity: .day) == .orderedDescending { return false }
        if calendar.compare(date, to: joinDate, toGranularity: .day) == .orderedAscending { return false }
        return true
    }
    
    // Animations
    func animateBigRing() {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        let progress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
        bigCircularRing.setProgress(min(progress, 1))
        percentLabel.text = "\(Int(progress * 100))%"
    }
    
    func animateWeekdays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {
            guard index < weekdayData.count,
                  let dayStack = view as? UIStackView,
                  let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
            else { continue }
            
            let date = dateForWeekday(at: index)
            let todayMinutes = StreakDataModel.shared.totalMinutes(for: date)
            let yesterdayMinutes = Calendar.current.isDate(date, inSameDayAs: yesterday) ? StreakDataModel.shared.totalMinutes(for: yesterday) : 0
            
            let todayProgress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
            let yesterdayProgress = CGFloat(yesterdayMinutes) / CGFloat(dailyGoalMinutes)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                ringView.animate(progress: todayProgress, yesterdayProgress: yesterdayProgress)
            }
            
            ringView.alpha = isDayEnabled(index: index) ? 1.0 : 0.3
        }
    }
    
    // Weekday Ring Taps
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
        
        // Previous day for comparison
        let calendar = Calendar.current
        let previousDate = calendar.date(byAdding: .day, value: -1, to: date)!
        let previousMinutes = StreakDataModel.shared.totalMinutes(for: previousDate)
        
        // Update big ring
        let progress = CGFloat(todayMinutes) / CGFloat(dailyGoalMinutes)
        bigCircularRing.setProgress(min(progress, 1))
        percentLabel.text = "\(Int(progress * 100))%"
        
        // Update goal label
        let completedHours = Double(todayMinutes) / 60
        let goalHours = Double(dailyGoalMinutes) / 60
        goalLabel.text = String(format: "%.1fh / %.0fh goal", completedHours, goalHours)
        
        // Update comparison label
        let diffMinutes = todayMinutes - previousMinutes
        let diffHours = Double(abs(diffMinutes)) / 60
        if diffMinutes == 0 {
            comparisonLabel.text = "Same as yesterday"
        } else if diffMinutes > 0 {
            comparisonLabel.text = String(format: "+%.1fh from yesterday", diffHours)
        } else {
            comparisonLabel.text = String(format: "-%.1fh from yesterday", diffHours)
        }
        
        // Update weekly insights dynamically
        updateWeeklyInsights(for: date)
        updateNavigationDateTitle(for: date)
    }
    
    // Labels
    func updateGoalLabel() {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        let completedHours = Double(todayMinutes) / 60
        let goalHours = Double(dailyGoalMinutes) / 60
        goalLabel.text = String(format: "%.1fh / %.0fh goal", completedHours, goalHours)
    }
    
    func updateWeeklyInsights(for selectedDate: Date? = nil) {
        let calendar = Calendar.current
        let today = Date()
        let referenceDate = selectedDate ?? today
        var totalsByDay: [Date: Int] = [:]
        
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: -i, to: referenceDate) {
                totalsByDay[calendar.startOfDay(for: day)] = StreakDataModel.shared.totalMinutes(for: day)
            }
        }
        
        // Total week hours
        let totalWeekMinutes = totalsByDay.values.reduce(0, +)
        let totalWeekHours = Double(totalWeekMinutes) / 60
        totalWeekTimeLabel.text = String(format: "This week: %.1fh", totalWeekHours)
        
        // Best day of the week
        if let bestDay = totalsByDay.max(by: { $0.value < $1.value })?.key,
           totalsByDay[bestDay]! > 0 {
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
    
    // Emphasis
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
            dayLabel.font = isToday
            ? .systemFont(ofSize: dayLabel.font.pointSize, weight: .semibold)
            : .systemFont(ofSize: dayLabel.font.pointSize, weight: .regular)
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
            dayLabel.font = (isToday || isSelected)
            ? .systemFont(ofSize: dayLabel.font.pointSize, weight: .semibold)
            : .systemFont(ofSize: dayLabel.font.pointSize, weight: .regular)
        }
    }
}
