//
//  CallMatchViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 18/11/25.
//

import UIKit
//
//  MatchViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 18/11/25.
//

import UIKit

class CallMatchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var sharedInterestsCollectionView: UICollectionView!
    @IBOutlet weak var startCallButton: UIButton!
    @IBOutlet weak var searchAgainButton: UIButton!

    // MARK: - Data (Pass these values dynamically)
    var userName: String = "Harshdeep Singh"
    var userCountry: String = ""
    var userCountryFlag: UIImage?
    var userBio: String = "i m not good person"
    var sharedInterests: [String] = ["movies" , "sports" , "coding" , "movies" , "sports" , "coding"]   // Dynamic list of interests
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        configureData()
        setupCollectionView()
    }
    
    
    
}

extension CallMatchViewController {

    func setupUI() {

        // Background is set from storyboard (light purple)
        
        // Profile Card styling
        cardView.layer.cornerRadius = 25
        cardView.layer.masksToBounds = true
        
        // Profile Image (circular)
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill

        // Buttons
        startCallButton.layer.cornerRadius = 25
        searchAgainButton.layer.cornerRadius = 25
    }
}


extension CallMatchViewController {
    
    func configureData() {
        nameLabel.text = userName
        bioLabel.text = userBio
        sharedInterestsCollectionView.reloadData()
    }
}

extension CallMatchViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func setupCollectionView() {
        sharedInterestsCollectionView.delegate = self
        sharedInterestsCollectionView.dataSource = self

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        // ⭐ SELF-SIZING CHIP CELLS
        layout.estimatedItemSize = CGSize(width: 80, height: 32)

        // ⭐ SPACE BETWEEN CELLS
        layout.minimumInteritemSpacing = 10   // horizontal spacing
        layout.minimumLineSpacing = 12        // vertical spacing between rows

        // ⭐ PADDING AROUND ALL SIDES
        layout.sectionInset = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

        sharedInterestsCollectionView.collectionViewLayout = layout
        sharedInterestsCollectionView.showsVerticalScrollIndicator = false
        sharedInterestsCollectionView.backgroundColor = .clear
    }


    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sharedInterests.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "InterestChipCell",
            for: indexPath
        ) as! InterestChipCell

        cell.configure(sharedInterests[indexPath.item])
        return cell
    }
}

extension CallMatchViewController {
    
    func createChipsLayout() -> UICollectionViewLayout {

        // ITEM
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(32)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // GROUP
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(32)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )


        group.interItemSpacing = .fixed(14)

        // SECTION
        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 6,
            leading: 10,
            bottom: 6,
            trailing: 10
        )

        section.interGroupSpacing = 14

        return UICollectionViewCompositionalLayout(section: section)
    }

}


extension CallMatchViewController {

    @IBAction func startCallTapped(_ sender: UIButton) {
        print("Start Call pressed")
        // navigate to call screen
    }

    @IBAction func searchAgainTapped(_ sender: UIButton) {
        print("Search Again pressed")
        // call API or refresh logic
    }
}
