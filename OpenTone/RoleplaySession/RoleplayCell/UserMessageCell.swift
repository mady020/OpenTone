
import UIKit

class UserMessageCell: UITableViewCell {

    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet var bubbleView: UIView!
    
    
 

    override func awakeFromNib() {
        super.awakeFromNib()
        
        bubbleView.layer.cornerRadius = 18
        
        bubbleView.clipsToBounds = true
        
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner, // top-left
            .layerMaxXMinYCorner ,   // top-right
            .layerMinXMaxYCorner
            
        ]
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
