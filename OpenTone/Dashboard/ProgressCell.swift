import UIKit

class ProgressCell: UICollectionViewCell {
    
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var overallProgressButton: UIButton!
    
    @IBAction func overallProgressButton(_ sender: UIButton) {
    }
    
    @IBOutlet var progressRingView: TimerRingView!
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 30
        clipsToBounds = true
        progressRingView.setProgress(value: 1, max: 5)
        progressRingView.tintColor = AppColors.primary
        backgroundColor = AppColors.cardBackground
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        
    }
}
