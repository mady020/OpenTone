import UIKit
class AppMessageCell: UITableViewCell {

    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        messageLabel.numberOfLines = 0
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        bubbleView.layer.cornerRadius = 18
        bubbleView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)

        bubbleView.translatesAutoresizingMaskIntoConstraints = false


    }
}
