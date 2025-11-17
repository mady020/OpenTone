//
//  HomeCollectionViewCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 13/11/25.
//
//
//  HomeCollectionViewCell.swift
//  OpenTone
//

import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initial UI setup for storyboard cell
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
    }
}
