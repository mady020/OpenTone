import UIKit

final class ProfileStoryboardCollectionViewController: UICollectionViewController {
    
    private var sessionUser: User? {
        SessionManager.shared.currentUser
    }

    /// The peer user to display in call modes. Falls back to sessionUser.
    var peerUser: User?

    /// Returns the user to display — peerUser in call mode, otherwise sessionUser.
    private var displayUser: User? {
        (isComingFromCall || isInCall) ? (peerUser ?? sessionUser) : sessionUser
    }

    private var callTimer: Timer?
    private var callStartDate: Date?


    
    var titleText = "Profile"
    
    var isComingFromCall = false
    
    var isInCall = false

    private let achievements = [
        ("First Call", "Completed your first call"),
        ("Consistency", "7-day streak achieved"),
        ("Explorer", "Tried 5 different topics")
    ]
    private var aiSuggestions: [String] = []
    private var isLoadingSuggestions = false
    private let fallbackSuggestions = [
        "What do you enjoy doing on weekends?",
        "Have you watched any good shows lately?",
        "What kind of music do you like?",
        "Where would you love to travel someday?"
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
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.register(
            SuggestedQuestionsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SuggestedQuestionsHeaderView.reuseIdentifier
        )

        setupNavigationBarButtons()

        if isComingFromCall || isInCall {
            generateAIQuestions()
        }
    }

    private func generateAIQuestions() {
        guard let peer = peerUser else {
            aiSuggestions = fallbackSuggestions
            return
        }

        let interests = peer.interests?.map { $0.title } ?? []
        guard !interests.isEmpty, GeminiAPIKeyManager.shared.hasAPIKey else {
            aiSuggestions = fallbackSuggestions
            return
        }

        isLoadingSuggestions = true
        collectionView.reloadData()

        Task {
            do {
                let questions = try await GeminiService.shared.generateQuestions(
                    for: interests,
                    peerName: peer.name
                )
                await MainActor.run {
                    self.aiSuggestions = questions.isEmpty ? self.fallbackSuggestions : questions
                    self.isLoadingSuggestions = false
                    self.collectionView.reloadSections(IndexSet(integer: Section.suggestedQuestions.rawValue))
                }
            } catch {
                await MainActor.run {
                    self.aiSuggestions = self.fallbackSuggestions
                    self.isLoadingSuggestions = false
                    self.collectionView.reloadSections(IndexSet(integer: Section.suggestedQuestions.rawValue))
                }
            }
        }
    }

    private func setupNavigationBarButtons() {
        // Only show settings & edit in normal profile mode (not during calls)
        guard !isComingFromCall && !isInCall else { return }

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
        
        if isInCall {
            switch section {
            case .profile:
                return 1
            case .interests:
                return 0
            case .suggestedQuestions:
                return isLoadingSuggestions ? 0 : aiSuggestions.count
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
                return displayUser?.interests?.count ?? 0
            case .stats:
                return 1
            case .suggestedQuestions:
                return isLoadingSuggestions ? 0 : aiSuggestions.count
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
            return displayUser?.interests?.count ?? 0
        case .stats:
            return 1
        case .achievements:
            return 0
        case .actions:
            return displayUser != nil ? 1 : 0
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
                name: displayUser?.name ?? "",
                country: "\(displayUser?.country?.flag ?? "") \(displayUser?.country?.name ?? "")",
                level: displayUser?.englishLevel?.rawValue.capitalized ?? "",
                bio: displayUser?.bio ?? "",
                streakText: "🔥 \(displayUser?.streak?.currentCount ?? 0) day streak",
                avatar: Self.loadAvatar(named: displayUser?.avatar),
                isPeer: isComingFromCall || isInCall
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

            cell.configure(calls: displayUser?.callRecordIDs.count ?? 0, roleplays: displayUser?.roleplayIDs.count ?? 0, jams: displayUser?.jamSessionIDs.count ?? 0)
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

            let question = aiSuggestions[indexPath.item]
            cell.configure(title: question, icon: UIImage(systemName: "lightbulb.fill"))
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

                // Settings is now in the nav bar, so hide the settings button
                cell.settingsButton.isHidden = true

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
            return UICollectionReusableView()
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
                return UICollectionReusableView()

            }
        
       
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        // Tapping the profile card in normal mode opens the profile editor
        if section == .profile && !isInCall && !isComingFromCall {
            didTapEditProfile()
        }
    }

    
    @objc private func didTapStartCall() {
        setTabBar(hidden: true)

        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.98
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isInCall = true
            self.isComingFromCall = false

            self.title = "In Call"
            self.navigationItem.largeTitleDisplayMode = .never

            self.startCallTimer()

            UIView.transition(
                with: self.collectionView,
                duration: 0.3,
                options: [.transitionCrossDissolve],
                animations: {
                    self.collectionView.reloadData()
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            )

        }
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
        
        cell.updateTimer(text: text)

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

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        // Refresh user data so updated session counts are picked up
        SessionManager.shared.refreshSession()
        collectionView.reloadData()
    }


    func goToEndCallChoice(){
        let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EndCall") as! CallEndedViewController
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapEndCall() {
        stopCallTimer()

        // --- Record the call ---
        let callDuration: TimeInterval
        if let start = callStartDate {
            callDuration = Date().timeIntervalSince(start)
        } else {
            callDuration = 0
        }

        // End the active CallSession (logs to HistoryDataModel)
        CallSessionDataModel.shared.endSession()

        // Create a CallRecord for the peer
        if let peer = peerUser {
            let record = CallRecord(
                participantID: peer.id,
                participantName: peer.name,
                participantAvatarURL: peer.avatar,
                participantBio: peer.bio,
                participantInterests: nil,
                callDate: Date(),
                duration: callDuration,
                userStatus: .offline
            )
            CallRecordDataModel.shared.addCallRecord(record)
            UserDataModel.shared.addCallRecordID(record.id)
        }

        // Log to streak/progress
        SessionProgressManager.shared.markCompleted(.oneToOne, topic: "Conversation")

        isInCall = false
        isComingFromCall = true

        title = titleText

        setTabBar(hidden: false)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()

        goToEndCallChoice()
    }


    
    @objc private func didTapSearchAgain() {
        // Pop back to CallSetupViewController so the user can search for a new peer
        guard let navController = navigationController else { return }
        for vc in navController.viewControllers {
            if vc is CallSetupViewController {
                navController.popToViewController(vc, animated: true)
                return
            }
        }
        // Fallback: just pop
        navController.popViewController(animated: true)
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
        stopCallTimer()
        isInCall = false
        isComingFromCall = false

        SessionManager.shared.logout()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()!

        guard let window = view.window else { return }
        window.rootViewController = vc
        window.makeKeyAndVisible()
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
                if self.isInCall || self.isComingFromCall {
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
                } else {
                    section.boundarySupplementaryItems = []
                }

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
