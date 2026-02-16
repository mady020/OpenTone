import UIKit

class FeedbackMistakeCell: UICollectionViewCell {

    @IBOutlet weak var originalLabel: UILabel!
    @IBOutlet weak var correctionLabel: UILabel!
    @IBOutlet weak var explanationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackMistakeCell, _) in
            self.applyTheme()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 24
        clipsToBounds = true
    }

    func configure(original: String, correction: String, explanation: String) {
        if !original.isEmpty {
            originalLabel.text = original.hasPrefix("✨") ? original : "❌ \(original)"
            originalLabel.textColor = original.hasPrefix("✨") ? AppColors.textPrimary : .systemRed
        } else {
            originalLabel.text = nil
        }

        if !correction.isEmpty {
            correctionLabel.text = correction.hasPrefix("No ") ? correction : "✔️ \(correction)"
            correctionLabel.textColor = .systemGreen
        } else {
            correctionLabel.text = nil
        }

        explanationLabel.text = explanation
        explanationLabel.textColor = .secondaryLabel
    }

    private func applyTheme() {
        layer.borderWidth = 1
        layer.borderColor = AppColors.cardBorder.cgColor
        layer.backgroundColor = AppColors.cardBackground.cgColor
    }
}

