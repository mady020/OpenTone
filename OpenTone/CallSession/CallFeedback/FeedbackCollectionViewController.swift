import UIKit

class FeedbackCollectionViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 3
        case 3: return 1
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackHeaderCell",
                for: indexPath
            ) as! FeedbackHeaderCell
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackMetricsCell",
                for: indexPath
            ) as! FeedbackMetricsCell
            
            cell.configure(
                    speechValue: "2 min",
                    speechProgress: 0.75,
                    fillerValue: "5 words",
                    fillerProgress: 0.30,
                    wpmValue: "23 WPM",
                    wpmProgress: 0.65,
                    pausesValue: "3 pauses",
                    pausesProgress: 0.40
                )
            return cell

        case 2:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackMistakeCell",
                for: indexPath
            ) as! FeedbackMistakeCell
            return cell
            
        case 3:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackTranscriptCell",
                for: indexPath
            ) as! FeedbackTranscriptCell
            return cell

        default:
            fatalError("Unexpected section index")
        }
    }
}

extension FeedbackCollectionViewController {

    private func createLayout() -> UICollectionViewCompositionalLayout {
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

            if sectionIndex == 0 {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 16, leading: 16, bottom: 4, trailing: 16
                )
                section.interGroupSpacing = 4
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 16, bottom: 16, trailing: 16
                )
                section.interGroupSpacing = 12
            }

            return section
        }
    }
}

