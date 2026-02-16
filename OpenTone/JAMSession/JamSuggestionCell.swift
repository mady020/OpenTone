
import Foundation
import UIKit

class JamSuggestionCell: UICollectionViewCell {

    @IBOutlet weak var suggestedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        let chipBackground = UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? AppColors.primary.withAlphaComponent(0.20)
                : AppColors.primaryLight
        }

        backgroundColor = chipBackground

        layer.cornerRadius = 25
        layer.borderWidth = 2
        layer.borderColor = AppColors.primary.cgColor
        layer.masksToBounds = true

        suggestedLabel.textAlignment = .center
        suggestedLabel.textColor = UIColor.label
        suggestedLabel.numberOfLines = 2
        suggestedLabel.adjustsFontSizeToFitWidth = false
        suggestedLabel.lineBreakMode = .byTruncatingTail
        suggestedLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: JamSuggestionCell, _) in
            self.layer.borderColor = AppColors.primary.cgColor
        }
    }

    func configure(text: String) {
        suggestedLabel.text = text
    }
}

