import UIKit

final class ProfileStoryboardCollectionViewController: UICollectionViewController {

    private let isLoggedIn: Bool = true

    private let interests = [
        "Movies", "Technology", "Gaming", "Travel", "Food", "Art"
    ]

    private let achievements = [
        ("First Call", "Completed your first call"),
        ("Consistency", "7-day streak achieved"),
        ("Explorer", "Tried 5 different topics")
    ]

    private enum Section: Int, CaseIterable {
        case profile
        case interests
        case stats
        case achievements
        case actions
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        collectionView.backgroundColor = UIColor(hex: "#F4F5F7")
        collectionView.collectionViewLayout = createLayout()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .profile:
            return 1
        case .interests:
            return interests.count
        case .stats:
            return 1
        case .achievements:
            return achievements.count
        case .actions:
            return isLoggedIn ? 1 : 0
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch section {

        case .profile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProfileCell",
                for: indexPath
            ) as! ProfileCell

            cell.configure(
                name: "Alex Johnson",
                country: "🇮🇳 India",
                level: "Intermediate",
                bio: "Learning communication skills through daily practice and real conversations.",
                streakText: "🔥 7 day streak",
                avatar: UIImage(named: "pp1")
            )
            return cell

        case .interests:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "InterestCell",
                for: indexPath
            ) as! InterestCell

            cell.configure(title: interests[indexPath.item])
            return cell

        case .stats:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "StatsCell",
                for: indexPath
            ) as! StatsCell

            cell.configure(calls: 12, roleplays: 8, jams: 5)
            return cell

        case .achievements:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AchievementCell",
                for: indexPath
            ) as! AchievementCell

            let achievement = achievements[indexPath.item]
            cell.configure(title: achievement.0, subtitle: achievement.1)
            return cell

        case .actions:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProfileActionsCell",
                for: indexPath
            ) as! ProfileActionsCell

            cell.settingsButton.addTarget(
                self,
                action: #selector(didTapSettings),
                for: .touchUpInside
            )

            cell.logoutButton.addTarget(
                self,
                action: #selector(didTapLogout),
                for: .touchUpInside
            )

            return cell
        }
    }


    @objc private func didTapSettings() {
        print("Settings tapped")
    }

    @objc private func didTapLogout() {
        print("Logout tapped")
    }
}


extension ProfileStoryboardCollectionViewController {

    private func createLayout() -> UICollectionViewCompositionalLayout {

        UICollectionViewCompositionalLayout { sectionIndex, _ in

            guard let section = Section(rawValue: sectionIndex) else {
                return nil
            }

            switch section {
            case .profile:
                return self.verticalSection(estimatedHeight: 220)
            case .interests:
                return self.horizontalPillsSection()
            case .stats:
                return self.verticalSection(estimatedHeight: 140)
            case .achievements:
                return self.verticalSection(estimatedHeight: 110)
            case .actions:
                let section = self.verticalSection(estimatedHeight: 120)
                section.contentInsets.bottom = 32
                return section
            }
        }
    }

    private func verticalSection(estimatedHeight: CGFloat) -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(estimatedHeight)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(estimatedHeight)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 16, bottom: 16, trailing: 16
        )
        section.interGroupSpacing = 12

        return section
    }

    private func horizontalPillsSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(44)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(80),
                heightDimension: .absolute(44)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 16, bottom: 16, trailing: 16
        )

        return section
    }
}
