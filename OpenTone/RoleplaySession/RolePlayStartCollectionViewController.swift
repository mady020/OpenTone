import UIKit

class RolePlayStartCollectionViewController: UICollectionViewController,
                                         UICollectionViewDelegateFlowLayout {

    
    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.collectionViewLayout = createLayout()
    }

    // MARK: - Number of Cells
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    // MARK: - Cell Provider
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.item {

        // CELL 0 - Description
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "DescriptionCell",
                for: indexPath) as! DescriptionCell
            
            if let scenario = currentScenario {
                print(scenario.description)
                print(scenario.estimatedTimeMinutes)
                cell.configure(
                    description: scenario.description,
                    time: "\(scenario.estimatedTimeMinutes) minutes"
                )
            }
            return cell

        // CELL 1 - Script + Phrases
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ScriptCell",
                for: indexPath) as! ScriptCell
            
            if let scenario = currentScenario {
                cell.configure(
                    guidedText: "Speak the provided lines to practice the conversation.",
                    keyPhrases: scenario.previewLines
                )
            }

            return cell

        // CELL 2 - Button
        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ButtonCell",
                for: indexPath) as! ButtonCell
            
            cell.scenarioId = currentScenario?.id
            return cell
        }
        
        
    }
}


extension RolePlayStartCollectionViewController {
    func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, env in

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)

           
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 16, leading: 16, bottom: 16, trailing: 16
                )
                section.interGroupSpacing = 16
        

            return section
        }
    }
}
