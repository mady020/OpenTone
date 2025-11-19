//
//  PlanCell.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit

class PlanCell: UICollectionViewCell {
    static let reuseId = "PlanCell"
    override init(frame: CGRect) {
            super.init(frame: frame)
        backgroundColor = .systemTeal
            //setupUI()
        }
    required init?(coder: NSCoder) { fatalError() }
}
