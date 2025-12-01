//
//  ButtonCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 28/11/25.
//

import UIKit

class ButtonCell: UICollectionViewCell {

    @IBOutlet weak var startButton: UIButton!
    static var reuseId = "ButtonCell";

    var onStartTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        startButton.layer.cornerRadius = 28
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
    }

    @IBAction func startTapped(_ sender: UIButton) {
        onStartTapped?()
    }
}
