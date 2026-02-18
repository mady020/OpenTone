
import UIKit

class UserMessageCell: UITableViewCell {

    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet var bubbleView: UIView!
    
    
 

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        selectionStyle = .none
        
        bubbleView.backgroundColor = AppColors.primary
        bubbleView.layer.cornerRadius = 18
        
        bubbleView.clipsToBounds = true
        
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner ,   
            .layerMinXMaxYCorner
            
        ]
        
        messageLabel.textColor = AppColors.textOnPrimary
        messageLabel.numberOfLines = 0
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
