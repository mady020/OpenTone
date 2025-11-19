//
//  StatsCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class StatsCell: UICollectionViewCell {
    static let reuseId = "StatsCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemBrown
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
