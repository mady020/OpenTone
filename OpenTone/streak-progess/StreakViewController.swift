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
    @IBOutlet weak var percentLabel: UILabel!
    @IBAction func historyButtonTapped(_ sender: UIButton) {
       // let storyboard = UIStoryboard(name: "streak-progess", bundle: nil)
        print("History tapped")   // IMPORTANT → test this first!

        let vc = storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var weekdaysStackView: UIStackView!
    
    private var hasAnimated = false
    private var weekdayData: [WeekdayStreak] = []

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

        loadWeekdayData()
        animateWeekdays()
        animateBigRing()
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



}
