
import UIKit

struct DayProgress {
    let weekdayShort: String   // "M", "T", "W"
    let progress: CGFloat      // 0.0 – 1.0
    let isSelected: Bool
}


class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var historyCardView: RoundedCardView!
    @IBOutlet weak var insightsCardView: RoundedCardView!
    @IBOutlet weak var weekdayCollection: UICollectionView!
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var deltaLabel: UILabel!
    
    let weekdays: [DayProgress] = [
        DayProgress(weekdayShort: "M", progress: 0.8, isSelected: false),
        DayProgress(weekdayShort: "T", progress: 0.7, isSelected: false),
        DayProgress(weekdayShort: "W", progress: 0.9, isSelected: false),
        DayProgress(weekdayShort: "T", progress: 0.85, isSelected: true),
        DayProgress(weekdayShort: "F", progress: 0.3, isSelected: false),
        DayProgress(weekdayShort: "S", progress: 0.0, isSelected: false),
        DayProgress(weekdayShort: "S", progress: 0.0, isSelected: false)
    ]
    
    
    
    override func viewDidLoad() {
            super.viewDidLoad()
            setupTapGestures()
        
        weekdayCollection.delegate = self
        weekdayCollection.dataSource = self
        // Do any additional setup after loading the view.
        }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HistoryViewSegue" {
            let dest = segue.destination as! HistoryViewController
            dest.weekData = weekdays   // example
        }
    }

        func setupTapGestures() {
            let historyTap = UITapGestureRecognizer(target: self, action: #selector(historyTapped))
            historyCardView.isUserInteractionEnabled = true
            historyCardView.addGestureRecognizer(historyTap)

            let insightsTap = UITapGestureRecognizer(target: self, action: #selector(insightsTapped))
            insightsCardView.isUserInteractionEnabled = true
            insightsCardView.addGestureRecognizer(insightsTap)
        }

        @objc func historyTapped() {
            performSegue(withIdentifier: "HistoryViewSegue", sender: self)
        }

        @objc func insightsTapped() {
            print("Insights tapped")
        }
    
//    func overallProgress() -> CGFloat {
//        // Example weekly progress values (0 → 1)
//        let weekProgress: [CGFloat] = [1.0, 0.7, 0.4, 1.0, 0.6, 0.0, 0.0]
//
//        let total = weekProgress.reduce(0, +)
//        return total / CGFloat(weekProgress.count)
//    }

    func overallProgress() -> CGFloat {
        guard !weekdays.isEmpty else { return 0 }
        return weekdays.map { $0.progress }.reduce(0, +) / CGFloat(weekdays.count)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let p = overallProgress() // 0 → 1
        bigCircularRing.animate(progress: p)
    

        percentLabel.text = "\(Int(p * 100))%"

    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weekdays.count
    }
    
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(
            withReuseIdentifier: "WeekdayCell",
            for: indexPath
        ) as! WeekDayCollectionViewCell
        
        cell.configure(with: weekdays[indexPath.row])
        return cell
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
