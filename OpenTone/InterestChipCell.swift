//
//  InterestChipCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 18/11/25.
//
import UIKit

class InterestChipCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    
    }

    func configure(_ text: String) {
        titleLabel.text = text
    }
}
