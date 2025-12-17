//
//  ProgressCell.swift
//  OpenTone
//
//  Created by M S on 10/12/25.
//

import UIKit

class ProgressCell: UICollectionViewCell {
    
    
    private let baseCardColor  = UIColor(hex: "#FBF8FF")
    
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var overallProgressButton: UIButton!
    
    @IBAction func overallProgressButton(_ sender: UIButton) {
    }
    @IBOutlet var progressRingView: TimerRingView!
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 30
        clipsToBounds = true
        progressRingView.setProgress(value: 1, max: 5)
        progressRingView.tintColor = UIColor(hex: "#5B3CC4")
        backgroundColor = baseCardColor
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        
    }
    
    
    


}
