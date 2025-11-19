//
//  ProfileCollectionViewController.swift
//  OpenTone
//
//  Created by Student on 19/11/25.
//

import UIKit


enum ProfileSection: Int, CaseIterable {
    case header
    case bio
    case interests
    case stats
    case plan
    case buttons
}


class ProfileCollectionViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: HeaderCell.reuseId)
        collectionView.register(BioCell.self, forCellWithReuseIdentifier: BioCell.reuseId)
        collectionView.register(InterestsCell.self, forCellWithReuseIdentifier: InterestsCell.reuseId)
        collectionView.register(StatsCell.self, forCellWithReuseIdentifier: StatsCell.reuseId)
        collectionView.register(PlanCell.self, forCellWithReuseIdentifier: PlanCell.reuseId)
        collectionView.register(ButtonsCell.self, forCellWithReuseIdentifier: ButtonsCell.reuseId)
        
        
        collectionView.collectionViewLayout = createLayout()
            collectionView.backgroundColor = .systemBackground
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return ProfileSection.allCases.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 3:
            return 3
        default:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let section = ProfileSection(rawValue: indexPath.section)!

        switch section {
        case .header:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: HeaderCell.reuseId,
                for: indexPath
            ) as! HeaderCell

        case .bio:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: BioCell.reuseId,
                for: indexPath
            ) as! BioCell

        case .interests:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: InterestsCell.reuseId,
                for: indexPath
            ) as! InterestsCell

        case .stats:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: StatsCell.reuseId,
                for: indexPath
            ) as! StatsCell

        case .plan:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: PlanCell.reuseId,
                for: indexPath
            ) as! PlanCell

        case .buttons:
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ButtonsCell.reuseId,
                for: indexPath
            ) as! ButtonsCell
        }
    }
    
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = ProfileSection(rawValue: sectionIndex) else {
                return nil
            }

            switch section {

            case .header:
                // Full width, fixed height header
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let sectionLayout = NSCollectionLayoutSection(group: group)
                return sectionLayout

            case .bio:
                // Full width, estimated height
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(80)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                return sectionLayout

            case .interests:
                // Full width, estimated height for tags
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(50)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                return sectionLayout

            case .stats:
                // Horizontal row of 3 equal boxes
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0/3.0),
                    heightDimension: .absolute(100)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 8
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                return sectionLayout

            case .plan:
                // Full width, fixed height
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(120)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                return sectionLayout

            case .buttons:
                // Full width, fixed height for settings/logout buttons
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(60)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 10
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)
                return sectionLayout
            }
        }
    }

}
