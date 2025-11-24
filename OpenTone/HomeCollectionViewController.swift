//
//  HomeCollectionViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 13/11/25.
//

import UIKit

enum DashboardSection: Int, CaseIterable {
    case conversation
    case twoMinuteSession
    case realLifeScenario
}

class HomeCollectionViewController: UICollectionViewController {

    
    var roleplays: [String] = [
        "GroceryShopping",
        "MakingFriends",
        "AirportCheckin",
        "OrderingFood",
        "BirthdayCelebration"
        
    ]
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(
            DashboardHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "DashboardHeader"
        )

        collectionView.collectionViewLayout = createLayout()
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "DashboardHeader",
            for: indexPath
        ) as! DashboardHeaderView

        switch DashboardSection(rawValue: indexPath.section)! {
        case .conversation:
            header.titleLabel.text = "Conversation"
        case .twoMinuteSession:
            header.titleLabel.text = "2 Minute Session"
        case .realLifeScenario:
            header.titleLabel.text = "Real Life Scenario"
        }

        return header
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DashboardSection.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch DashboardSection(rawValue: section)! {
        case .conversation:
            return 6
        case .twoMinuteSession:
            return 1
        case .realLifeScenario:
            return 5
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath
        ) as! HomeCollectionViewCell

        switch DashboardSection(rawValue: indexPath.section)! {

        case .conversation:
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            if(indexPath.row == 0){
                cell.imageView.image = UIImage(named: "Call")
                cell.backgroundColor = .clear
            }else{
                cell.backgroundColor = .purple
            }
           

        case .twoMinuteSession:
            cell.imageView.image = UIImage(named: "Jam")
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            cell.backgroundColor = .clear
            

        case .realLifeScenario:
            cell.imageView.image = UIImage(named: roleplays[indexPath.row])
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            cell.backgroundColor = .clear
        }

        return cell
    }
}

// MARK: - COMPOSITIONAL LAYOUT
extension HomeCollectionViewController {

    func createLayout() -> UICollectionViewLayout {

        UICollectionViewCompositionalLayout { sectionIndex, _ in

            guard let sectionType = DashboardSection(rawValue: sectionIndex) else { return nil }

            switch sectionType {

            case .conversation:
                return self.horizontalConversationSection()

            case .twoMinuteSession:
                return self.fullWidthSection()

            case .realLifeScenario:
                return self.horizontalScrollingSection()
            }
        }
    }

    // ✅ Horizontal Conversation Cards
    func horizontalConversationSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(380),
                heightDimension: .absolute(220)
            )
        )

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        return section
    }

    func fullWidthSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(169)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        return section
    }

    func horizontalScrollingSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.2),
                heightDimension: .absolute(130)
            )
        )

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(160),
                heightDimension: .absolute(120)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        return section
    }
}

