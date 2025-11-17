//
//  DashboardHeaderView.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 13/11/25.
//

import UIKit

class DashboardHeaderView: UICollectionReusableView {

    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.boldSystemFont(ofSize: 22)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
