
import UIKit

struct DayProgress {
    let weekdayShort: String   // "M", "T", "W"
    let progress: CGFloat      // 0.0 – 1.0
    let isSelected: Bool
}


class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var weekdayCollection: UICollectionView!
    @IBOutlet weak var bigCircularRing: BigCircularProgressView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var deltaLabel: UILabel!
    
    var weekdays: [DayProgress] = [
        DayProgress(weekdayShort: "M", progress: 0.8, isSelected: false),
        DayProgress(weekdayShort: "T", progress: 0.7, isSelected: false),
        DayProgress(weekdayShort: "W", progress: 0.9, isSelected: false),
        DayProgress(weekdayShort: "T", progress: 0.85, isSelected: true),
        DayProgress(weekdayShort: "F", progress: 0.3, isSelected: false),
        DayProgress(weekdayShort: "S", progress: 0.0, isSelected: false),
        DayProgress(weekdayShort: "S", progress: 0.0, isSelected: false)
    ]
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let p = SessionProgressManager.shared.overallProgress()  // value 0 → 1

        bigCircularRing.progress = CGFloat(p)   // animate ring
        percentLabel.text = "\(Int(p * 100))%"  // update percentage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        weekdayCollection.delegate = self
        weekdayCollection.dataSource = self
        // Do any additional setup after loading the view.
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
