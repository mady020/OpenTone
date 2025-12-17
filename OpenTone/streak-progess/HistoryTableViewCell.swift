//
//  HistoryTableViewCell.swift
//  OpenTone
//
//  Created by Student on 11/12/25.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {

    
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()

            // Rounded card look
            cardBackgroundView?.layer.cornerRadius = 12
            cardBackgroundView?.clipsToBounds = true
        }

        func configure(with item: HistoryItem) {

            // Main title (e.g. "2 Min Session")
            titleLabel.text = item.title

            // Subtitle (you already store this)
            subtitleLabel.text = item.subtitle

            // Lower details text
            detailsLabel.text = "⏱ Duration: \(item.duration)   ★ \(item.xp)"

            // Icon from SF Symbols
            iconImageView.image = UIImage(systemName: item.iconName)
            iconImageView.tintColor = .systemPurple
        }
    }

