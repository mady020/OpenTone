//
//  SuggestionCell.swift
//  OpenTone
//
//  Created by Student on 27/11/25.
//

import Foundation
import UIKit

class JamSuggestionCell: UICollectionViewCell {
    
    @IBOutlet weak var suggestedLabel: UILabel!
    
    override func awakeFromNib() {
           super.awakeFromNib()

        let ringColor = UIColor(red: 0.42, green: 0.05, blue: 0.68, alpha: 1.0)
           let ringLight = UIColor(red: 146/255, green: 117/255, blue: 234/255, alpha: 0.08)

           backgroundColor = ringLight

           layer.cornerRadius = 25   // for height 50
           layer.borderWidth = 2
           layer.borderColor = ringColor.cgColor
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
