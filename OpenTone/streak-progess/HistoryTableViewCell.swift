//
//  HistoryTableViewCell.swift
//  OpenTone
//
//  Created by Student on 08/12/25.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {

    
    @IBOutlet weak var xpLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()

        cardView.layer.cornerRadius = 16
        cardView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
    }

    func configure(with item: HistoryItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        topicLabel.text = "Topic : \(item.topic)"
        durationLabel.text = item.duration
        xpLabel.text = "★ Gained \(item.xp) XP"
        iconImageView.image = UIImage(systemName: item.iconName)
    }
}
