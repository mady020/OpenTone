//
//  InterestsCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class InterestsCell: UICollectionViewCell {
    static let reuseId = "InterestsCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemPink
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
