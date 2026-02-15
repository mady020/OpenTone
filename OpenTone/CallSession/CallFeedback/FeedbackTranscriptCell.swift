import UIKit

class FeedbackTranscriptCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var transcriptLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    
        layer.cornerRadius = 24
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.backgroundColor = AppColors.cardBackground.cgColor

        titleLabel.textColor = AppColors.textPrimary
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        transcriptLabel.isHidden = false
        transcriptLabel.numberOfLines = 0
        transcriptLabel.textColor = AppColors.textPrimary
        transcriptLabel.font = .systemFont(ofSize: 14)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = AppColors.cardBorder.cgColor
            layer.backgroundColor = AppColors.cardBackground.cgColor
        }
    }

    func configure(transcript: String) {
        transcriptLabel.text = transcript
    }
}

