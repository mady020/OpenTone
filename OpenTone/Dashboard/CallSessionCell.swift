//
//  CallSessionCell.swift
//  OpenTone
//
//  Created by M S on 10/12/25.
//

import UIKit

class CallSessionCell: UICollectionViewCell {
    
    private let baseCardColor  = UIColor(hex: "#FBF8FF")
    
    @IBOutlet var image: UIImageView!
    
    @IBOutlet var buttonLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = baseCardColor
        layer.cornerRadius = 30
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
    }
    
     func configure(imageURL: String, labelText: String){
        image.image = UIImage(systemName: imageURL)
        buttonLabel.text = labelText
    }
    
}
