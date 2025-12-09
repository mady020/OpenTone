
import UIKit

enum DashboardSection: Int, CaseIterable {
    case conversation
    case twoMinuteSession
    case realLifeScenario
}

class HomeCollectionViewController: UICollectionViewController {
    
    var user: User?

    
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
            return 1
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
                cell.textLabel.text = "Find A Peer"
            }else{
                cell.backgroundColor = .purple
            }
           

        case .twoMinuteSession:
            cell.imageView.image = UIImage(named: "Jam")
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            cell.backgroundColor = .clear
            cell.textLabel.text = "Start JAM Session"

        case .realLifeScenario:
            cell.imageView.image = UIImage(named: roleplays[indexPath.row])
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            cell.backgroundColor = .clear
            cell.configure(title: "roleplays")
            cell.textLabel.text = roleplays[indexPath.row]
        }

        return cell
    }
}


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
                widthDimension: .fractionalWidth(1.0),
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
    
    

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let section = DashboardSection(rawValue: indexPath.section)!

        switch section {

        case .conversation:


            if indexPath.row == 0 {
                print("1-to-1 Call tapped")

                let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)

                guard let navController = storyboard.instantiateInitialViewController() as? UINavigationController else {
                    print("CallStoryBoard initial is not NavigationController")
                    return
                }

                guard let rootVC = navController.viewControllers.first else {
                    print("No root VC in CallStoryBoard")
                    return
                }

                self.navigationController?.pushViewController(rootVC, animated: true)
            }

        case .twoMinuteSession:
            print("2 Min JAM tapped")
            tabBarController?.selectedIndex = 2

        case .realLifeScenario:
            print("Scenario tapped: \(indexPath.row)")
            tabBarController?.selectedIndex = 1
        }
    }

}

