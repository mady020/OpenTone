import UIKit

class ScoreViewController: UIViewController {

    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var PointsLabel: UILabel!

    var score: Int = 0
    var pointsEarned: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground
        ScoreLabel.text = "Score : \(score)"
        ScoreLabel.textColor = AppColors.textPrimary
        ScoreLabel.font = .systemFont(ofSize: 28, weight: .bold)
        PointsLabel.text = "+ \(pointsEarned) points"
        PointsLabel.textColor = AppColors.primary
        PointsLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    }
}
