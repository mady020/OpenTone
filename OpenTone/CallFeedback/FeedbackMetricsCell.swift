
import UIKit

class FeedbackMetricsCell: UICollectionViewCell {

    // MARK: - Speech
    @IBOutlet weak var speechTitleLabel: UILabel!
    @IBOutlet weak var speechValueLabel: UILabel!
    @IBOutlet weak var speechProgressView: UIProgressView!

    // MARK: - Filler
    @IBOutlet weak var fillerTitleLabel: UILabel!
    @IBOutlet weak var fillerValueLabel: UILabel!
    @IBOutlet weak var fillerProgressView: UIProgressView!

    // MARK: - WPM
    @IBOutlet weak var wpmTitleLabel: UILabel!
    @IBOutlet weak var wpmValueLabel: UILabel!
    @IBOutlet weak var wpmProgressView: UIProgressView!

    // MARK: - Pauses
    @IBOutlet weak var pausesTitleLabel: UILabel!
    @IBOutlet weak var pausesValueLabel: UILabel!
    @IBOutlet weak var pausesProgressView: UIProgressView!

    // MARK: - Container Views
    @IBOutlet weak var speechView: UIView!
    @IBOutlet weak var fillerView: UIView!
    @IBOutlet weak var wpmView: UIView!
    @IBOutlet weak var pausesView: UIView!


    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
    }

    // MARK: - Styling
    private func styleUI() {
        let cards = [speechView, fillerView, wpmView, pausesView]

        cards.forEach {
            $0?.layer.cornerRadius = 30
            $0?.clipsToBounds = true
            $0?.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        }
    }

    // MARK: - Configure Cell with Real Data
    func configure(
        speechValue: String,
        speechProgress: Float,
        fillerValue: String,
        fillerProgress: Float,
        wpmValue: String,
        wpmProgress: Float,
        pausesValue: String,
        pausesProgress: Float
    ) {
        // Speech
        speechTitleLabel.text = "Speech Length"
        speechValueLabel.text = speechValue
        speechProgressView.progress = speechProgress

        // Filler
        fillerTitleLabel.text = "Filler Words"
        fillerValueLabel.text = fillerValue
        fillerProgressView.progress = fillerProgress

        // WPM
        wpmTitleLabel.text = "Words Per Minute"
        wpmValueLabel.text = wpmValue
        wpmProgressView.progress = wpmProgress

        // Pauses
        pausesTitleLabel.text = "Pauses"
        pausesValueLabel.text = pausesValue
        pausesProgressView.progress = pausesProgress
    }
}

