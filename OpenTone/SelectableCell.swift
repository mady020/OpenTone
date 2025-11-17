//
//  SelectableCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 16/11/25.
//



import UIKit

class SelectableCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray.cgColor
    }

    func configure(with item: SelectableItem) {
        titleLabel.text = item.title
        
        if item.isSelected {
            contentView.backgroundColor = UIColor.systemPurple
            titleLabel.textColor = .white
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = .white
            titleLabel.textColor = .darkGray
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.gray.cgColor
        }
    }
}
