import UIKit

final class ProfileStoryboardCollectionViewController: UICollectionViewController {

    private let isLoggedIn: Bool = true
    
    private var callTimer: Timer?
    private var callStartDate: Date?

    
    var titleText = "Profile"
    
    var isComingFromCall = false
    
    var isInCall = false


    private let interests = [
        "Movies", "Technology", "Gaming", "Travel", "Food", "Art"
    ]

    private let achievements = [
        ("First Call", "Completed your first call"),
        ("Consistency", "7-day streak achieved"),
        ("Explorer", "Tried 5 different topics")
    ]
    private let suggestions = [
        ("First Call", "Completed your first call"),
        ("Consistency", "7-day streak achieved"),
        ("Explorer", "Tried 5 different topics")
    ]


    private enum Section: Int, CaseIterable {
        case profile
        case interests
        case stats
        case achievements
        case suggestedQuestions
        case actions
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = titleText
        collectionView.backgroundColor = UIColor(hex: "#F4F5F7")
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.register(
            SuggestedQuestionsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SuggestedQuestionsHeaderView.reuseIdentifier
        )


    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        guard let section = Section(rawValue: section) else { return 0 }
        
        if isInCall {
            switch section {
            case .profile:
                return 1
            case .interests:
                return 0
            case .suggestedQuestions:
                return suggestions.count
            case .actions:
                return 1
            default:
                return 0
            }
        }
        
        if isComingFromCall {
            switch section {
            case .profile:
                return 1
            case .interests:
                return interests.count
            case .stats:
                return 1
            case .actions:
                return 1
            default:
                return 0
            }
        }
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
        default:
            return 0
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
        
        case .suggestedQuestions:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "SuggestionCallCell",
                for: indexPath
            ) as! SuggestionCallCell

            let suggestion = suggestions[indexPath.item]
            cell.configure(title: suggestion.1)
            return cell

        case .actions:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProfileActionsCell",
                for: indexPath
            ) as! ProfileActionsCell

            if isInCall {
                cell.configure(mode: .inCall, timerText: "00:00")
                cell.logoutButton.addTarget(
                    self,
                    action: #selector(didTapEndCall),
                    for: .touchUpInside
                )

            } else if isComingFromCall {
                cell.configure(mode: .postCall)

                cell.settingsButton.addTarget(
                    self,
                    action: #selector(didTapStartCall),
                    for: .touchUpInside
                )

                cell.logoutButton.addTarget(
                    self,
                    action: #selector(didTapSearchAgain),
                    for: .touchUpInside
                )

            } else {
                cell.configure(mode: .normal)

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
            }

            return cell

            
            
        }
        
    }
    
    private func setTabBar(hidden: Bool) {
        guard let tabBar = tabBarController?.tabBar else { return }

        UIView.animate(withDuration: 0.25) {
            tabBar.alpha = hidden ? 0 : 1
        }
    }

    
    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unsupported supplementary kind")
        }

        let section = Section(rawValue: indexPath.section)

        switch section {
        case .suggestedQuestions:
            return collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SuggestedQuestionsHeaderView.reuseIdentifier,
                for: indexPath
            )

        default:
            // This should NEVER be called if layout is correct
            fatalError("Unexpected header request for section \(String(describing: section))")
        }
    }


    
    @objc private func didTapStartCall() {
        isInCall = true
        isComingFromCall = false

        title = "In Call"
        navigationItem.largeTitleDisplayMode = .never

        setTabBar(hidden: true)

        startCallTimer()

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @objc private func updateCallTimer() {
        guard let start = callStartDate else { return }

        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60

        let formatted = String(format: "%02d:%02d", minutes, seconds)

        updateTimerLabel(formatted)
    }
    
    private func updateTimerLabel(_ text: String) {
        let indexPath = IndexPath(
            item: 0,
            section: Section.actions.rawValue
        )

        guard
            let cell = collectionView.cellForItem(at: indexPath)
                as? ProfileActionsCell
        else { return }

        cell.configure(mode: .inCall, timerText: text)
    }


    
    private func startCallTimer() {
        callStartDate = Date()

        callTimer?.invalidate()
        callTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateCallTimer),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        callStartDate = nil
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isInCall {
            stopCallTimer()
        }
    }

    
    @objc private func didTapEndCall() {
        stopCallTimer()

        isInCall = false
        isComingFromCall = true

        title = titleText
        navigationItem.largeTitleDisplayMode = .automatic

        setTabBar(hidden: false)

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }


    
    @objc private func didTapSearchAgain() {
        print("Settings tapped")
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
            case .suggestedQuestions:
                let section = self.verticalSection(estimatedHeight: 110)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(44)
                )

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )

                section.boundarySupplementaryItems = [header]
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
