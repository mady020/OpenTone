import UIKit

class FeedbackCollectionViewController: UICollectionViewController {

    /// Optional feedback data — if nil, shows sample/placeholder data.
    var feedback: Feedback?

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

            if let fb = feedback {
                let mins = Int(fb.durationInSeconds) / 60
                let secs = Int(fb.durationInSeconds) % 60
                cell.configure(
                    speechValue: String(format: "%d:%02d", mins, secs),
                    speechProgress: min(Float(fb.durationInSeconds) / 120.0, 1.0),
                    fillerValue: "\(fb.totalWords) words",
                    fillerProgress: min(Float(fb.totalWords) / 200.0, 1.0),
                    wpmValue: "\(Int(fb.wordsPerMinute)) WPM",
                    wpmProgress: min(Float(fb.wordsPerMinute) / 150.0, 1.0),
                    pausesValue: fb.comments,
                    pausesProgress: 0.5
                )
            } else {
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
            }
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

            let transcript = feedback?.transcript ?? """
            You: Hey! How are you doing today?

            Partner: I'm doing great, thanks for asking! How about you?

            You: I'm good too. I learned some new things…
            Like I'm learning stock market now a days.

            Partner: That's interesting! What part of stock market are you learning?

            You: I am learning how to analysis the markets and invest properly.

            Partner: Nice! Keep it up — it's a great skill to build.

            You: Yes, I want to improve my financial knowledge. Still a lot to learn.
            """

            cell.configure(transcript: transcript)

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

