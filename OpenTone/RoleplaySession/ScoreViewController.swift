import UIKit

class ScoreViewController: UIViewController {

    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var PointsLabel: UILabel!

    var score: Int = 0
    var pointsEarned: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        ScoreLabel.text = "Score : \(score)"
        PointsLabel.text = "+ \(pointsEarned) points"
    }
}
