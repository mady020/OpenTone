
import UIKit

enum DashboardSection: Int, CaseIterable {
    case progress
    case continueJam
    case completeTask
    case callSession
    case recommended
}



class HomeCollectionViewController: UICollectionViewController {
    
    
    private var hasUnfinishedLastTask: Bool {
        guard let task = lastTask else { return false }
        return task.isCompleted == false
    }


    var lastTask: Activity?
    var currentProgress: Int?
    var commitment : Int?
    var savedJamSession: JamSession?
    var savedRoleplaySession: RoleplaySession?
    var savedRoleplayScenario: RoleplayScenario?

    /// Cached speech profile fetched from BackendSpeechService on each appearance.
    private var cachedSpeechProfile: UserSpeechProfile?
    /// WPM delta stored after the last /analyze call (read from UserDefaults).
    private var lastWpmDelta: Double? {
        let v = UserDefaults.standard.double(forKey: "opentone.lastWpmDelta")
        return v == 0 ? nil : v
    }

    /// Whether we have any saved session (jam or roleplay) to continue. At most 1.
    private var hasSavedSession: Bool {
        savedJamSession != nil || (savedRoleplaySession != nil && savedRoleplayScenario != nil)
    }
    
    

    var recommendedScenarios: [RoleplayScenario] = []
    private var pendingProgressReload: DispatchWorkItem?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        syncFromSession()
        recommendedScenarios = RoleplayScenarioDataModel.shared.getAll()

        collectionView.register(
            DashboardHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "DashboardHeader"
        )

        collectionView.register(
            ProgressCell.self,
            forCellWithReuseIdentifier: ProgressCell.reuseID
        )

        collectionView.register(
            ContinueJamCell.self,
            forCellWithReuseIdentifier: ContinueJamCell.reuseID
        )

        collectionView.register(
            CallSessionCell.self,
            forCellWithReuseIdentifier: CallSessionCell.reuseID
        )

        collectionView.register(
            HomeCollectionViewCell.self,
            forCellWithReuseIdentifier: "Cell"
        )

        collectionView.collectionViewLayout = createLayout()
        collectionView.backgroundColor = AppColors.screenBackground

        setupProfileBarButton()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStreakDataLoaded),
            name: StreakDataModel.streakDataLoadedNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHistoryDataLoaded),
            name: HistoryDataModel.historyDataLoadedNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProgressDataUpdated),
            name: SessionProgressManager.progressDataUpdatedNotification,
            object: nil
        )
    }

    @objc private func handleStreakDataLoaded() {
        scheduleProgressReload(fullReload: false)
    }

    @objc private func handleHistoryDataLoaded() {
        scheduleProgressReload(fullReload: false)
    }

    @objc private func handleProgressDataUpdated() {
        scheduleProgressReload(fullReload: false)
    }

    private func scheduleProgressReload(fullReload: Bool) {
        pendingProgressReload?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.syncFromSession()

            guard self.isViewLoaded else { return }
            if fullReload {
                self.collectionView.reloadData()
            } else {
                self.collectionView.reloadSections(IndexSet(integer: DashboardSection.progress.rawValue))
            }
        }

        pendingProgressReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    deinit {
        pendingProgressReload?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupProfileBarButton() {
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(openProfile)
        )
        profileButton.tintColor = AppColors.primary
        navigationItem.rightBarButtonItem = profileButton
    }

    @objc private func openProfile() {
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        guard let profileNav = storyboard.instantiateInitialViewController() as? UINavigationController,
              let profileVC = profileNav.viewControllers.first else { return }
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncFromSession()
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
        if StreakDataModel.shared.isLoaded && HistoryDataModel.shared.isLoaded {
            collectionView.reloadData()
        } else {
            scheduleProgressReload(fullReload: true)
        }
        fetchSpeechProfile()
    }

    private func fetchSpeechProfile() {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString, !userId.isEmpty else { return }
        Task {
            do {
                let profile = try await BackendSpeechService.shared.fetchProfile(userId: userId)
                self.cachedSpeechProfile = profile
                self.collectionView.reloadSections(IndexSet(integer: DashboardSection.progress.rawValue))
            } catch {
                print("[Dashboard] Speech profile fetch failed (non-fatal): \(error.localizedDescription)")
            }
        }
    }

    private func syncFromSession() {
        guard let user = SessionManager.shared.currentUser else { return }

        commitment = user.streak?.commitment ?? 0
        currentProgress = user.streak?.currentCount ?? 0
        lastTask = SessionManager.shared.lastUnfinishedActivity

        // Load saved sessions — show at most 1 on dashboard
        savedJamSession = JamSessionDataModel.shared.getSavedSession()
        savedRoleplaySession = RoleplaySessionDataModel.shared.getSavedSession()
        savedRoleplayScenario = RoleplaySessionDataModel.shared.getSavedScenario()

        // If both exist, keep the jam (or whichever you prefer) and drop the other
        if savedJamSession != nil && savedRoleplaySession != nil {
            savedRoleplaySession = nil
            savedRoleplayScenario = nil
        }
    }

    /// Build the data struct that drives the redesigned progress card.
    private func buildProgressData() -> ProgressCellData {
        let streak = StreakDataModel.shared.getStreak()
        let streakDays = streak?.currentCount ?? 0
        let dailyGoal = streak?.commitment ?? 0
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())

        // Build Mon → Sun weekly minutes
        var weeklyMinutes: [Int] = []
        let calendar = Calendar.current
        let todayWeekdayIndex = mondayBasedWeekdayIndex()

        for i in 0..<7 {
            let diff = i - todayWeekdayIndex
            let date = calendar.date(byAdding: .day, value: diff, to: Date()) ?? Date()
            weeklyMinutes.append(StreakDataModel.shared.totalMinutes(for: date))
        }

        let completedCount = HistoryDataModel.shared.getAllActivities().count
        let growthSummary: String? = {
            let trend = HistoryDataModel.shared.feedbackTrendPoints(limit: 6, smoothingWindow: 3)
            guard let first = trend.first, let last = trend.last, trend.count >= 2 else {
                return nil
            }

            let overallDelta = last.overall - first.overall
            let confidenceDelta = last.confidence - first.confidence
            let arrow = overallDelta >= 0 ? "↑" : "↓"

            return String(
                format: "%@ %.0f overall • %@ %.0f confidence",
                arrow,
                abs(overallDelta),
                confidenceDelta >= 0 ? "↑" : "↓",
                abs(confidenceDelta)
            )
        }()

        return ProgressCellData(
            streakDays: streakDays,
            todayMinutes: todayMinutes,
            dailyGoalMinutes: dailyGoal,
            weeklyMinutes: weeklyMinutes,
            speechProfile: cachedSpeechProfile,
            lastWpmDelta: lastWpmDelta,
            growthSummary: growthSummary,
            hasCompletedSessions: completedCount > 0
        )
    }

    private func mondayBasedWeekdayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    @objc private func openStreak() {
        let vc = UINavigationController(rootViewController: StreakViewController())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    // MARK: - Resume Saved JAM

    private func resumeSavedJamSession() {
        // Load the saved session as active
        JamSessionDataModel.shared.resumeSavedSession()

        // Switch to the JAM tab
        guard let tabBar = tabBarController else { return }

        // Find the JAM tab index (the one whose root VC is TwoMinuteJamViewController)
        var jamTabIndex: Int?
        if let viewControllers = tabBar.viewControllers {
            for (index, vc) in viewControllers.enumerated() {
                let rootVC: UIViewController?
                if let nav = vc as? UINavigationController {
                    rootVC = nav.viewControllers.first
                } else {
                    rootVC = vc
                }
                if rootVC is TwoMinuteJamViewController {
                    jamTabIndex = index
                    break
                }
            }
        }

        guard let targetIndex = jamTabIndex else { return }

        // Switch tab
        tabBar.selectedIndex = targetIndex

        // Push PrepareJam from the JAM tab's navigation controller
        if let jamNav = tabBar.viewControllers?[targetIndex] as? UINavigationController {
            jamNav.popToRootViewController(animated: false)

            let storyboard = UIStoryboard(name: "JamSessionStoryBoard", bundle: nil)
            if let prepareVC = storyboard.instantiateViewController(
                withIdentifier: "PrepareJamViewController"
            ) as? PrepareJamViewController {
                prepareVC.forceTimerReset = false
                jamNav.pushViewController(prepareVC, animated: true)
            }
        }
    }

    // MARK: - Resume Saved Roleplay

    private func resumeSavedRoleplaySession() {
        guard let (session, scenario) = RoleplaySessionDataModel.shared.resumeSavedSession() else {
            return
        }

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(
            withIdentifier: "RoleplayChatVC"
        ) as? RoleplayChatViewController else { return }

        chatVC.scenario = scenario
        chatVC.session = session
        chatVC.entryPoint = .dashboard

        navigationController?.pushViewController(chatVC, animated: true)
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
            return UICollectionReusableView()

        case .continueJam:
            if hasSavedSession {
                header.titleLabel.text = "Continue where you left off"
                return header
            } else {
                return UICollectionReusableView()
            }
           
        case .completeTask:
            if hasUnfinishedLastTask {
                header.titleLabel.text = "Complete your task"
                return header
            } else {
                return UICollectionReusableView()
            }

            
        case .callSession:
            header.titleLabel.text = "Start a session"
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
        case .continueJam:
            return hasSavedSession ? 1 : 0
        case .completeTask:
            return hasUnfinishedLastTask ? 1 : 0
        case .callSession:
            return 1
        case .recommended:
            return recommendedScenarios.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch DashboardSection(rawValue: indexPath.section)! {

        case .progress:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProgressCell.reuseID,
                for: indexPath
            ) as! ProgressCell

            cell.configure(with: buildProgressData())
            cell.onSeeProgressTapped = { [weak self] in
                self?.openStreak()
            }

            
            return cell


        case .continueJam:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ContinueJamCell.reuseID,
                for: indexPath
            ) as! ContinueJamCell

            if let session = savedJamSession {
                cell.configure(with: .jam(
                    topic: session.topic,
                    secondsLeft: session.secondsLeft,
                    phase: session.phase
                ))
                cell.onContinueTapped = { [weak self] in
                    self?.resumeSavedJamSession()
                }
            } else if let session = savedRoleplaySession,
                      let scenario = savedRoleplayScenario {
                cell.configure(with: .roleplay(
                    scenarioTitle: scenario.title,
                    progress: session.currentLineIndex,
                    total: scenario.script.count
                ))
                cell.onContinueTapped = { [weak self] in
                    self?.resumeSavedRoleplaySession()
                }
            }

            return cell

        case .completeTask:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "LastTaskCell",
                for: indexPath
            ) as! LastTaskCell

            if let task = lastTask {
                cell.configure(
                    title: task.title,
                    imageURL: task.imageURL
                )
            }

            cell.backgroundColor = AppColors.cardBackground
            cell.continueButton.backgroundColor = AppColors.primary

            return cell

            


        case .callSession:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CallSessionCell.reuseID,
                for: indexPath
            ) as! CallSessionCell
            cell.configure(
                icon: "phone.fill",
                title: "AI Call Session",
                subtitle: "Practice speaking with an AI coach",
                iconBackground: AppColors.primary
            )
            return cell

        case .recommended:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            ) as! HomeCollectionViewCell

            let scenario = recommendedScenarios[indexPath.row]
            cell.configure(with: scenario)


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
                return self.progressCardSection()

            case .continueJam:
                return self.hasSavedSession
                    ? self.fullWidthSection()
                    : self.nothingLayout()

            case .completeTask:
                return self.hasUnfinishedLastTask
                    ? self.fullWidthSection()
                    : self.nothingLayout()
                
            case .callSession:
                return self.callSessionSection()

            case .recommended:
                return self.horizontalScrollingSection()
            }
        }
    }


    func progressCardSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(230)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: item.layoutSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        return section
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

    func callSessionSection() -> NSCollectionLayoutSection {

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(76)
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

        // Use fractionalWidth(1) with a near-zero estimated height to avoid
        // the "Invalid absolute dimension, must be > 0" assertion.
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(1)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
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
            repeatingSubitem: item,
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
                heightDimension: .absolute(120)
            )
        )

        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.93),
                heightDimension: .absolute(120)
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

        case .continueJam:
            if savedJamSession != nil {
                resumeSavedJamSession()
            } else if savedRoleplaySession != nil {
                resumeSavedRoleplaySession()
            }

        case .completeTask:

            print("Complete Task Clicked!")
        

        case .callSession:
            // AI Speech Coach — launches the AI call flow
            // AICallController is fully programmatic (no storyboard).
            let callVC = AICallController()
            callVC.modalPresentationStyle = .fullScreen
            callVC.modalTransitionStyle = .crossDissolve
            present(callVC, animated: true)

        case .recommended:

            let scenario = recommendedScenarios[indexPath.item]

            let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "RolePlayStartVC"
            ) as! RolePlayStartCollectionViewController

            vc.currentScenario = scenario
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)

        }
    }

}

