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
                    let dayKey = Calendar.current.startOfDay(for: selectedDate)

                    let vc = storyboard?.instantiateViewController(
                        withIdentifier: "HistoryViewController"
                    ) as! HistoryViewController

                    vc.items = historyByDate[dayKey] ?? []
                    vc.selectedDate = selectedDate

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
    private let dailyTargetSessions = 3
    
    private var historyByDate: [Date: [HistoryItem]] = [:]

      
      /// USER JOINED YESTERDAY
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
            loadSampleHistoryData()


            let todayIndex = mondayBasedWeekdayIndex(from: Date())
            selectedWeekdayIndex = todayIndex

            animateWeekdays()
            animateBigRing()
            updateGoalLabel()
            updateYesterdayComparisonLabel()
            updateWeeklyInsights()
            updateNavigationDateTitle()
            emphasizeTodayRingAndLabel()
            setupWeekdayRingTaps()
        }

        
        private func loadSampleHistoryData() {

               let calendar = Calendar.current
               let today = calendar.startOfDay(for: Date())
               let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

               historyByDate[yesterday] = [
                   HistoryItem(
                       title: "RolePlays",
                       subtitle: "You completed a roleplay session",
                       topic: "Interview Practice",
                       duration: "15 min",
                       xp: "25 XP",
                       iconName: "theatermasks.fill"
                   )
               ]

               historyByDate[today] = [
                   HistoryItem(
                       title: "2 Min Session",
                       subtitle: "You completed a speaking session",
                       topic: "Time Travel",
                       duration: "2 min",
                       xp: "15 XP",
                       iconName: "mic.fill"
                   ),
                   HistoryItem(
                       title: "1 to 1 Call",
                       subtitle: "You completed a live call",
                       topic: "Mock Interview",
                       duration: "10 min",
                       xp: "20 XP",
                       iconName: "phone.fill"
                   )
               ]
           }

        // Sample DataSet

        func loadWeekdayData() {

            weekdayData = Array(
                repeating: WeekdayStreak(completed: 0, target: dailyTargetSessions),
                count: 7
            )

            let calendar = Calendar.current
            let todayIndex = mondayBasedWeekdayIndex(from: Date())
            let yesterdayIndex = mondayBasedWeekdayIndex(from: joinDate)

            // SAMPLE: yesterday progress
            weekdayData[yesterdayIndex] = WeekdayStreak(
                completed: 2,
                target: dailyTargetSessions
            )

            // SAMPLE: today progress
            weekdayData[todayIndex] = WeekdayStreak(
                completed: 1,
                target: dailyTargetSessions
            )
        }

        func mondayBasedWeekdayIndex(from date: Date) -> Int {
            let weekday = Calendar.current.component(.weekday, from: date)
            return (weekday + 5) % 7
        }

        // Availability Rules
        func isDayEnabled(index: Int) -> Bool {

            let calendar = Calendar.current
            let today = Date()

            let dateForIndex = dateForWeekday(at: index)

            if calendar.compare(dateForIndex, to: today, toGranularity: .day) == .orderedDescending {
                return false // future day
            }

            if calendar.compare(dateForIndex, to: joinDate, toGranularity: .day) == .orderedAscending {
                return false // before join date
            }

            return true
        }

        // Animations

        func animateBigRing() {

            let todayIndex = mondayBasedWeekdayIndex(from: Date())
            let progress = weekdayData[todayIndex].progress

            bigCircularRing.setProgress(progress)
            percentLabel.text = "\(Int(progress * 100))%"
        }

        func animateWeekdays() {

            for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

                guard
                    index < weekdayData.count,
                    let dayStack = view as? UIStackView,
                    let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
                else { continue }

                guard isDayEnabled(index: index) else {
                    ringView.animate(progress: 0)
                    ringView.alpha = 0.3
                    continue
                }

                let progress = weekdayData[index].progress

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                    ringView.animate(progress: progress)
                }
            }
        }

        // Taps

        func setupWeekdayRingTaps() {

            for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

                guard
                    let dayStack = view as? UIStackView,
                    let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
                else { continue }

                ringView.onTap = { [weak self] in
                    guard
                        let self = self,
                        self.isDayEnabled(index: index)
                    else { return }

                    self.selectedWeekdayIndex = index
                    self.refreshWeekdayEmphasis()
                    self.showProgressForDay(at: index)
                }
            }
        }

        // Selection

        func showProgressForDay(at index: Int) {

            guard index < weekdayData.count else { return }

            let progress = weekdayData[index].progress

            bigCircularRing.setProgress(progress)
            percentLabel.text = "\(Int(progress * 100))%"

            updateNavigationDateTitle(for: dateForWeekday(at: index))
        }

        func dateForWeekday(at index: Int) -> Date {

            let calendar = Calendar.current
            let today = Date()
            let todayIndex = mondayBasedWeekdayIndex(from: today)
            let diff = index - todayIndex

            return calendar.date(byAdding: .day, value: diff, to: today) ?? today
        }

        // Labels

        func updateGoalLabel() {

            let completedMinutes = 60 // sample
            let completedHours = Double(completedMinutes) / 60
            let goalHours = Double(dailyGoalMinutes) / 60

            goalLabel.text =
                String(format: "%.1fh / %.0fh goal", completedHours, goalHours)
        }

        func updateYesterdayComparisonLabel() {
            comparisonLabel.text = "+0.5h from yesterday"
        }

        func updateWeeklyInsights() {
            totalWeekTimeLabel.text = "This week: 1.5h"
            bestDayLabel.text = "Best day: Yesterday"
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

                guard
                    let dayStack = view as? UIStackView,
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

                guard
                    let dayStack = view as? UIStackView,
                    let dayLabel = dayStack.arrangedSubviews.first as? UILabel,
                    let ringView = dayStack.arrangedSubviews[1] as? WeekdayRingView
                else { continue }

                let enabled = isDayEnabled(index: index)
                let isToday = index == todayIndex
                let isSelected = index == selectedWeekdayIndex

                ringView.setEmphasis(
                    isToday: isToday && enabled,
                    isSelected: isSelected && enabled
                )

                ringView.alpha = enabled ? 1.0 : 0.3
                dayLabel.alpha = enabled ? 1.0 : 0.3

                dayLabel.font = (isToday || isSelected)
                    ? .systemFont(ofSize: dayLabel.font.pointSize, weight: .semibold)
                    : .systemFont(ofSize: dayLabel.font.pointSize, weight: .regular)
            }
        }
    }
