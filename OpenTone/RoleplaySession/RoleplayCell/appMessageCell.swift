import UIKit
class AppMessageCell: UITableViewCell {

    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        selectionStyle = .none

        messageLabel.numberOfLines = 0
        messageLabel.textColor = AppColors.textPrimary
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        bubbleView.backgroundColor = AppColors.cardBackground
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.borderColor = AppColors.cardBorder.cgColor

        
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner, // top-left
            .layerMaxXMinYCorner ,   // top-right
            .layerMaxXMaxYCorner
        ]
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false


    }
}
