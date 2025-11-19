//
//  HeaderCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class HeaderCell: UICollectionViewCell {
    static let reuseId = "HeaderCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemCyan
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
