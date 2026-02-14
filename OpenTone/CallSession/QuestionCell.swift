

import UIKit
class QuestionCell: UICollectionViewCell {

    @IBOutlet weak var questionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        questionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        questionLabel.textColor = AppColors.textPrimary
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        questionLabel.preferredMaxLayoutWidth = questionLabel.frame.width
    }


    func configure(_ text: String) {
        questionLabel.text = text
    }
}
