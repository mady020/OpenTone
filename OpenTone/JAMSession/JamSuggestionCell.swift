
import Foundation
import UIKit

class JamSuggestionCell: UICollectionViewCell {

    @IBOutlet weak var suggestedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        let outlineColor = UIColor(
            red: 86/255,
            green: 61/255,
            blue: 189/255,
            alpha: 1
        )

        let backgroundLight = UIColor(
            red: 242/255,
            green: 238/255,
            blue: 255/255,
            alpha: 1
        )

        backgroundColor = backgroundLight

        layer.cornerRadius = 25
        layer.borderWidth = 2
        layer.borderColor = outlineColor.cgColor
        layer.masksToBounds = true

        suggestedLabel.textAlignment = .center
        suggestedLabel.textColor = .black
        suggestedLabel.numberOfLines = 1
        suggestedLabel.adjustsFontSizeToFitWidth = true
        suggestedLabel.minimumScaleFactor = 0.60
        suggestedLabel.lineBreakMode = .byClipping
        suggestedLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
    }

    func configure(text: String) {
        suggestedLabel.text = text
    }
}

