
import UIKit

enum DashboardSection: Int, CaseIterable {
    case progress
    case completeTask
    case callSession
    case recommended
}



class HomeCollectionViewController: UICollectionViewController {
    
    var user: User?
    
    var isNewUser = false
    
    // MARK: - Colors
    private let screenBackground  = UIColor(hex: "#F4F5F7")
    private let baseCardColor     = UIColor(hex: "#FBF8FF")
    private let selectedCardColor = UIColor(hex: "#5B3CC4")
    private let normalTint        = UIColor(hex: "#333333")
    private let selectedTint      = UIColor.white
    private let cardBorderColor   = UIColor(hex: "#E6E3EE")
    
    
    var roleplays: [RoleplayScenario]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roleplays = RoleplayScenarioDataModel.shared.getAll()
        
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
        case .progress:
        return header
           
        case .completeTask:
            if(!isNewUser){
                header.titleLabel.text = "Complete your task"
            }
            
        case .callSession:
            header.titleLabel.text = "Start call session with"
        case .recommended:
            header.titleLabel.text = "Recommended for you"
        }
        return header
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DashboardSection.allCases.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch DashboardSection(rawValue: section)! {
        case .progress:
            return 1
        case .completeTask:
            if (isNewUser){
                return 0
            }
            return 1
        case .callSession:
            return 2
        case .recommended:
            guard let roleplays else {return 0}
            return roleplays.count > 5 ? 5 : roleplays.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch DashboardSection(rawValue: indexPath.section)! {

        case .progress:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProgressCell",
                for: indexPath
            ) as! ProgressCell

            cell.backgroundColor = baseCardColor
            cell.overallProgressButton.backgroundColor = selectedCardColor
            cell.progressRingView.backgroundColor = baseCardColor
            return cell

        case .completeTask:
           
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "LastTaskCell",
                    for: indexPath
                ) as! LastTaskCell
                
            
            cell.backgroundColor = baseCardColor
            cell.continueButton.backgroundColor = selectedCardColor
                
                return cell
            


        case .callSession:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "CallSessionCell",
                for: indexPath
            ) as! CallSessionCell
            if( indexPath.item == 0){
                cell.configure(imageURL: "person.line.dotted.person.fill", labelText: "Human")
            }else{
                cell.configure(imageURL: "sparkles", labelText: "AI")
            }
            return cell

        case .recommended:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            ) as! HomeCollectionViewCell
            
            if let roleplays {
                
                let title = roleplays[indexPath.row].title
                let imageName = title.replacingOccurrences(of: " ", with: "")
                
                cell.imageView.image = UIImage(named: imageName)
                cell.imageView.contentMode = .scaleAspectFill
                cell.imageView.clipsToBounds = true
                cell.configure(title: "roleplays")
                cell.textLabel.text = title
            }
            
            return cell
        }
    }

}

extension HomeCollectionViewController {

    func createLayout() -> UICollectionViewLayout {

        UICollectionViewCompositionalLayout { sectionIndex, _ in

            guard let sectionType = DashboardSection(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .progress:
                return self.horizontalcompleteTaskSection()

            case .completeTask:
                if(self.isNewUser){
                    return self.nothingLayout()
                }
                return self.fullWidthSection()

            case .callSession:
                return self.twoItemFixedSection()

            case .recommended:
                return self.horizontalScrollingSection()
            }
        }
    }


    func horizontalcompleteTaskSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(380),
                heightDimension: .absolute(160)
            )
        )

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        return section
    }

    func fullWidthSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(124)
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
    
    func nothingLayout() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(0),
                heightDimension: .absolute(0)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .absolute(0),
            heightDimension: .absolute(0)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return section
    }
    
    func twoItemFixedSection() -> NSCollectionLayoutSection {

    
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(124)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 16
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(124)
            ),
            subitem: item,
            count: 2
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

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 0
        )

        return section
    }


    
    func horizontalScrollingSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(130)
            )
        )

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.93),
                heightDimension: .absolute(130)
            ),
            subitems: [item, item]
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
        case .progress:
            print("Progress Clicked")

        case .completeTask:

            print("Complete Task Clicked!")
        

        case .callSession:
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

        case .recommended:
            print("Scenario tapped: \(indexPath.row)")
            let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "RoleplayStartVC") as! RolePlayStartCollectionViewController
            if let roleplays{
                vc.currentScenario = roleplays[indexPath.row]
                vc.title = roleplays[indexPath.row].title
            }
        
            navigationController?.pushViewController(vc, animated: true)
        }
    }

}

