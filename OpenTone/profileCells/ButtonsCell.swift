//
//  ButtonsCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class ButtonsCell: UICollectionViewCell {
    static let reuseId = "ButtonsCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemBlue
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
