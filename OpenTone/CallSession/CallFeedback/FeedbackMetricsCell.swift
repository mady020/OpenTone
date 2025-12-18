
import UIKit

class FeedbackMetricsCell: UICollectionViewCell {


    @IBOutlet weak var speechTitleLabel: UILabel!
    @IBOutlet weak var speechValueLabel: UILabel!
    @IBOutlet weak var speechProgressView: UIProgressView!

 
    @IBOutlet weak var fillerTitleLabel: UILabel!
    @IBOutlet weak var fillerValueLabel: UILabel!
    @IBOutlet weak var fillerProgressView: UIProgressView!

  
    @IBOutlet weak var wpmTitleLabel: UILabel!
    @IBOutlet weak var wpmValueLabel: UILabel!
    @IBOutlet weak var wpmProgressView: UIProgressView!

  
    @IBOutlet weak var pausesTitleLabel: UILabel!
    @IBOutlet weak var pausesValueLabel: UILabel!
    @IBOutlet weak var pausesProgressView: UIProgressView!

 
    @IBOutlet weak var speechView: UIView!
    @IBOutlet weak var fillerView: UIView!
    @IBOutlet weak var wpmView: UIView!
    @IBOutlet weak var pausesView: UIView!


    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
    }

  
    private func styleUI() {
        let cards = [speechView, fillerView, wpmView, pausesView]

        cards.forEach {
            $0?.clipsToBounds = true
            $0?.layer.cornerRadius = 24
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = AppColors.cardBorder.cgColor
            $0?.layer.backgroundColor = AppColors.cardBackground.cgColor
        }
    }


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

        speechTitleLabel.text = "Speech Length"
        speechValueLabel.text = speechValue
        speechProgressView.progress = speechProgress
        speechProgressView.progressTintColor = AppColors.primary
    

        fillerTitleLabel.text = "Filler Words"
        fillerValueLabel.text = fillerValue
        fillerProgressView.progress = fillerProgress
        fillerProgressView.progressTintColor = AppColors.primary
  
        wpmTitleLabel.text = "Words Per Minute"
        wpmValueLabel.text = wpmValue
        wpmProgressView.progress = wpmProgress
        wpmProgressView.progressTintColor = AppColors.primary


        pausesTitleLabel.text = "Pauses"
        pausesValueLabel.text = pausesValue
        pausesProgressView.progressTintColor = AppColors.primary
    }
}

