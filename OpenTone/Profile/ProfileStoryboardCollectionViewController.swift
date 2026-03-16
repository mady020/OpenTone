import UIKit

final class ProfileStoryboardCollectionViewController: UICollectionViewController {
    
    private var sessionUser: User? {
        SessionManager.shared.currentUser
    }

    /// Returns the user to display — peerUser in call mode, otherwise sessionUser.
    private var displayUser: User? {
        sessionUser
    }

    var titleText = "Profile"

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

        title = titleText
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()

        setupNavigationBarButtons()
        
        NotificationCenter.default.addObserver(
            forName: HistoryDataModel.historyDataLoadedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.collectionView.reloadData()
        }
    }

    private func setupNavigationBarButtons() {

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        settingsButton.tintColor = AppColors.primary

        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(didTapEditProfile)
        )
        editButton.tintColor = AppColors.primary

        navigationItem.rightBarButtonItems = [settingsButton, editButton]
    }

    @objc private func didTapEditProfile() {
        let editVC = EditProfileViewController()
        editVC.onProfileUpdated = { [weak self] in
            SessionManager.shared.refreshSession()
            self?.collectionView.reloadData()
        }
        navigationController?.pushViewController(editVC, animated: true)
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
            return displayUser?.interests?.count ?? 0
        case .stats:
            return 1
        case .achievements:
            return 0
        case .actions:
            return displayUser != nil ? 1 : 0
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
                name: displayUser?.name ?? "",
                country: "\(displayUser?.country?.flag ?? "") \(displayUser?.country?.name ?? "")",
                level: displayUser?.englishLevel?.rawValue.capitalized ?? "",
                bio: displayUser?.bio ?? "",
                streakText: "🔥 \(displayUser?.streak?.currentCount ?? 0) day streak",
                avatar: Self.loadAvatar(named: displayUser?.avatar)
            )

            return cell

        case .interests:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "InterestCell",
                for: indexPath
            ) as! InterestCell

    
            let interests: [InterestItem] = Array(displayUser?.interests ?? [])

           
            cell.configure(title:  interests[indexPath.item] .title)
            return cell

        case .stats:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "StatsCell",
                for: indexPath
            ) as! StatsCell

            let isCurrentUser = displayUser?.id == SessionManager.shared.currentUser?.id
            
            // Always derive counts from HistoryDataModel (roleplayIDs/jamSessionIDs on User are not persisted)
            let callsCount = isCurrentUser ? HistoryDataModel.shared.searchHistory(by: .aiCall).count : 0
            let roleplaysCount = isCurrentUser ? HistoryDataModel.shared.searchHistory(by: .roleplay).count : 0
            let jamsCount = isCurrentUser ? HistoryDataModel.shared.searchHistory(by: .jam).count : 0

            cell.configure(calls: callsCount, roleplays: roleplaysCount, jams: jamsCount)
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
        
            cell.configure(mode: .normal)

            // Settings is now in the nav bar, so hide the settings button
            cell.settingsButton.isHidden = true

            cell.logoutButton.addTarget(
                self,
                action: #selector(didTapLogout),
                for: .touchUpInside
            )

            return cell

            
            
        }
        
    }
    
    private func setTabBar(hidden: Bool) {
        guard let tabBar = tabBarController?.tabBar else { return }

        UIView.animate(withDuration: 0.25) {
            tabBar.alpha = hidden ? 0 : 1
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        // Tapping the profile card in normal mode opens the profile editor
        if section == .profile {
            didTapEditProfile()
        }
    }

    
    @objc private func didTapSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    /// Loads an avatar image from asset catalog or from the documents directory (custom photos).
    static func loadAvatar(named name: String?) -> UIImage? {
        guard let name = name else { return UIImage(named: "pp1") }

        // Try asset catalog first
        if let assetImage = UIImage(named: name) {
            return assetImage
        }

        // Try documents directory (custom photo)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(name)
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }

        return UIImage(named: "pp1")
    }
    
    @objc private func didTapLogout() {
        Task { @MainActor in
            await SessionManager.shared.logoutAsync()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()!

            guard let window = self.view.window else { return }
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
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
