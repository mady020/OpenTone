//
//  ProfileCell.swift
//  OpenTone
//
//  Created by M S on 01/12/25.
//

import UIKit


class ProfileCell: UICollectionViewCell {
    static var reuseId = "ProfileCell"
    
    @IBOutlet var profileImage: UIImageView!
    
    @IBOutlet var namelabel: UILabel!
    
    @IBOutlet var countryLabel: UILabel!
    
    @IBOutlet var levelLabel: UILabel!
    
    @IBOutlet var streakLabel: UILabel!
    
    
    @IBOutlet var bioLabel: UILabel!
    

    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImage.layer.cornerRadius = profileImage.frame.width / 2
        profileImage.layer.masksToBounds = true
    }

    
    
}
