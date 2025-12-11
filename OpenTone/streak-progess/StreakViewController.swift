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

}
