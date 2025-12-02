import UIKit


class ProfileCollectionViewController: UICollectionViewController {
    
    var interests = [
        "Movies",
        "Technology",
        "Gaming",
        "Travel",
        "Food",
        "Art"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return interests.count
            
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProfileCell",
                for: indexPath
            ) as! ProfileCell
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "InterestCell",
                for: indexPath
            ) as! InterestCell
            cell.interestButton.titleLabel?.text = interests[indexPath.row]
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
}



extension ProfileCollectionViewController {

    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, env in

            switch sectionIndex {

            case 0:
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
                    top: 4, leading: 16, bottom: 16, trailing: 16
                )
                return section

            case 1:
                
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(44)
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

                
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

                return section


                
                
            default:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(80)
                    )
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(80)
                    ),
                    subitems: [item]
                )
                return NSCollectionLayoutSection(group: group)
            }
        }
    }

}
