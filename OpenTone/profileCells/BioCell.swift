//
//  BioCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class BioCell: UICollectionViewCell {
    static let reuseId = "BioCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemRed
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
