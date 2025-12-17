//
//  LastTaskCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 11/12/25.
//


import UIKit





class LastTaskCell: UICollectionViewCell {
    
    private let baseCardColor  = UIColor(hex: "#FBF8FF")

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!

    var onContinueTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 30
        clipsToBounds = true
        continueButton.clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
    }

    @IBAction func continueTapped(_ sender: UIButton) {
        onContinueTapped?()
    }

   
}
