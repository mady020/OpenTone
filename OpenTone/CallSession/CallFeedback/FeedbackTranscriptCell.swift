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

        transcriptLabel.text =
        """
        You: Hey! How are you doing today?

        Partner: I'm doing great, thanks for asking! How about you?

        You: I'm good too. I learned some new things…  
        Like I'm learning stock market now a days.

        Partner: That's interesting! What part of stock market are you learning?

        You: I am learning how to analysis the markets and invest properly.

        Partner: Nice! Keep it up — it's a great skill to build.

        You: Yes, I want to improve my financial knowledge. Still a lot to learn.
        """
    }
}

