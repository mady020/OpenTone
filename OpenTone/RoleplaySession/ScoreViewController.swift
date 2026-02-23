import UIKit

class ScoreViewController: UIViewController {

    @IBOutlet weak var ScoreLabel: UILabel!
    @IBOutlet weak var PointsLabel: UILabel!
    @IBOutlet weak var exitButton: UIButton!

    var score: Int = 0
    var pointsEarned: Int = 0

    /// Called after the score screen is dismissed so the presenter can navigate away.
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground
        ScoreLabel.text = "Score : \(score)"
        ScoreLabel.textColor = AppColors.textPrimary
        ScoreLabel.font = .systemFont(ofSize: 28, weight: .bold)
        PointsLabel.text = "+ \(pointsEarned) points"
        PointsLabel.textColor = AppColors.primary
        PointsLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        // In case the button isn't wired via storyboard action, add a programmatic target
        exitButton?.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }

    @IBAction func exitTapped(_ sender: Any? = nil) {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}
