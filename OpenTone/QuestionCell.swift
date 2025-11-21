//
//  QuestionCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 19/11/25.
//

import UIKit
class QuestionCell: UICollectionViewCell {

    @IBOutlet weak var questionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        questionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        questionLabel.textColor = .black
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }

    func configure(_ text: String) {
        questionLabel.text = text
    }
}
