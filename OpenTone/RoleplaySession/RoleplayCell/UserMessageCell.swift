//
//  UserMessageCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 02/12/25.
//

import UIKit

class UserMessageCell: UITableViewCell {

    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet var bubbleView: UIView!
    
    
 

    override func awakeFromNib() {
        super.awakeFromNib()
        
        bubbleView.layer.cornerRadius = 18
//        bubbleView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.22)
        
        bubbleView.clipsToBounds = true
        
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
//

//        
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
