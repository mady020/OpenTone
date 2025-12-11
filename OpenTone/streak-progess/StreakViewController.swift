//
//  StreakViewController.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

import UIKit

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
        animateWeekdays()
        super.viewDidAppear(animated)
        animateBigRing()
    }
    
    func animateBigRing() {

        let overallProgress: CGFloat = 0.65   // 65%

        bigCircularRing.setProgress(overallProgress)
        percentLabel.text = "\(Int(overallProgress * 100))%"
    }


    func animateWeekdays() {

        let progress: [CGFloat] = [0.6, 0.4, 0.8, 0.5, 0, 0, 0]

        for (index, view) in weekdaysStackView.arrangedSubviews.enumerated() {

            let dayStack = view as! UIStackView
            let ringView = dayStack.arrangedSubviews[1] as! WeekdayRingView

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(index)) {
                ringView.animate(progress: progress[index])
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


}
