import UIKit

struct CommitmentOption: Hashable {
    let title: String
    let subtitle: String
    let number: Int
}

final class CommitmentViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var continueButton: UIButton!

    // MARK: - Data

    private let options: [CommitmentOption] = [
        CommitmentOption(title: "5 minutes per day", subtitle: "Quick daily progress", number: 5),
        CommitmentOption(title: "10 minutes per day", subtitle: "Steady improvement", number: 10),
        CommitmentOption(title: "20 minutes per day", subtitle: "Fast growth", number: 20),
        CommitmentOption(title: "No schedule", subtitle: "I'll practice whenever I want", number: 0)
    ]

    private var selectedOption: CommitmentOption? {
        didSet { updateContinueState() }
    }

    // MARK: - Colors
    private let bgSoft = UIColor(hex: "#F4F5F7")
    private let baseCard = UIColor(hex: "#FBF8FF")
    private let selectedCard = UIColor(hex: "#5B3CC4")
    private let baseTint = UIColor(hex: "#333333")
    private let selectedTint = UIColor.white
    private let borderColor = UIColor(hex: "#E6E3EE")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        preloadFromSession()
        updateContinueState()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = bgSoft

        titleLabel.text = "Daily practice commitment"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(hex: "#2E2E2E")

        subtitleLabel.text = "Choose one option to continue"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor(hex: "#6B6B6B")

        continueButton.layer.cornerRadius = 18
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.setTitleColor(.white, for: .normal)
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(100)
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 14
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 14, leading: 16, bottom: 140, trailing: 16
            )

            return section
        }

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Session Sync

    /// Preselect commitment if user already has one
    private func preloadFromSession() {
        guard
            let user = SessionManager.shared.currentUser,
            let streak = user.streak
        else { return }

        selectedOption = options.first { $0.number == streak.commitment }
    }

    // MARK: - State

    private func updateContinueState() {
        let enabled = selectedOption != nil
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled
            ? selectedCard
            : UIColor(hex: "#C9C7D6")
    }

    // MARK: - Actions

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard
            let selected = selectedOption,
            var user = SessionManager.shared.currentUser
        else { return }

        // Persist commitment
        user.streak = Streak(
            commitment: selected.number,
            currentCount: 1,
            longestCount: 0
        )

        SessionManager.shared.updateSessionUser(user)

        // Clear onboarding-only state
        InterestSelectionStore.shared.selected.removeAll()

        goToDashboard()
    }

    // MARK: - Navigation

    private func goToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(
            withIdentifier: "MainTabBarController"
        )

        guard let window = view.window else { return }

        let transition = CATransition()
        transition.duration = 0.35
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        window.layer.add(transition, forKey: kCATransition)
        window.rootViewController = tabBarVC
        window.makeKeyAndVisible()
    }
}

// MARK: - Collection View

extension CommitmentViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let option = options[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CommitmentCard.reuseIdentifier,
            for: indexPath
        ) as! CommitmentCard

        let isSelected = selectedOption == option

        cell.configure(
            with: option,
            backgroundColor: isSelected ? selectedCard : baseCard,
            tintColor: isSelected ? selectedTint : baseTint,
            borderColor: borderColor
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedOption = options[indexPath.item]
        collectionView.reloadData()
    }
}

