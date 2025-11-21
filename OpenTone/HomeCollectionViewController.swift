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

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell(s)
//        collectionView.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        // Register header class for section headers
        collectionView.register(
            DashboardHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "DashboardHeader"
        )

        // Apply layout that includes header (make sure your layout adds boundarySupplementaryItems)
        collectionView.collectionViewLayout = createLayout()
    }


    // MARK: - Collection View Sections Count
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DashboardSection.allCases.count
    }

    // MARK: - Items Per Section
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = DashboardSection(rawValue: section)!

        switch sectionType {
        case .conversation:
            return 1
        case .twoMinuteSession:
            return 1
        case .realLifeScenario:
            return 8   // horizontal cards
        }
    }

    // MARK: - Cell For Item
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! HomeCollectionViewCell
        
        // ---- Configure sections ----
        switch DashboardSection(rawValue: indexPath.section)! {
            
        case .conversation:
            cell.backgroundColor = .systemPurple.withAlphaComponent(0.3)
            cell.textLabel.text = "Start 1-on-1 Call"

        case .twoMinuteSession:
            cell.backgroundColor = .systemBlue.withAlphaComponent(0.3)
            cell.textLabel.text = "Start a JAM"

        case .realLifeScenario:
            cell.backgroundColor = .systemOrange.withAlphaComponent(0.3)
            cell.textLabel.text = "Scenario \(indexPath.row + 1)"
        }

        return cell
    }
}

//
// MARK: - COMPOSITIONAL LAYOUT
//
extension HomeCollectionViewController {

    func createLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection? in

            guard let sectionType = DashboardSection(rawValue: sectionIndex) else { return nil }

            switch sectionType {

            case .conversation, .twoMinuteSession:
                return self.fullWidthSection()

            case .realLifeScenario:
                return self.horizontalScrollingSection()
            }
        }
    }

    // Full width block (Conversation + 2 Min Session)
    func fullWidthSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(220)
            )
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        
        
        // ADD HEADER
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

    // Horizontal cards (Real Life Scenario)
    func horizontalScrollingSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.2),
                heightDimension: .absolute(120)
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
        // ADD HEADER
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
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Which section was tapped
        let section = DashboardSection(rawValue: indexPath.section)!

        switch section {

//        case .conversation:
            // 1-to-1 call section tapped
//            print("1 to 1 call tapped")
////            tabBarController?.selectedIndex = 1   // ← change to index of your Call tab
//          
//            // Load the storyboard
//            let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
//
//            // Instantiate the Navigation Controller (initial VC)
//            guard let navController = storyboard.instantiateInitialViewController() else {
//                print(" Could not load initial view controller from CallStoryBoard")
//                return
//            }
//            navController.modalPresentationStyle = .popover
//            self.present(navController, animated: true)
//            
            
            
        case .conversation:
            print("1 to 1 call tapped")

            let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)

            // Initial VC is a UINavigationController → we must unwrap it
            guard let navFromStoryboard = storyboard.instantiateInitialViewController() as? UINavigationController else {
                print("Initial VC is not a navigation controller")
                return
            }

            // Get its root view controller
            guard let rootVC = navFromStoryboard.viewControllers.first else {
                print("No root VC found in storyboard navigation controller")
                return
            }

            // Push the root view controller
            self.navigationController?.pushViewController(rootVC, animated: true)

            
            

        case .twoMinuteSession:
            print("2 minute session tapped")
            tabBarController?.selectedIndex = 2

        case .realLifeScenario:
            print("scenario card tapped: \(indexPath.row)")
            tabBarController?.selectedIndex = 1
        }
    }

}
