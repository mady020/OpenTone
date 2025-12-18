import UIKit

final class OnboardingInterestsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var requirementLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var showAllButton: UIButton!
    @IBOutlet private weak var continueButton: UIButton!

    // MARK: - Data

    private let popularItems: [InterestItem] = [
        InterestItem(title: "Technology", symbol: "cpu"),
        InterestItem(title: "Gaming", symbol: "gamecontroller.fill"),
        InterestItem(title: "Travel", symbol: "airplane"),
        InterestItem(title: "Fitness", symbol: "dumbbell"),
        InterestItem(title: "Food", symbol: "fork.knife"),
        InterestItem(title: "Music", symbol: "music.note.list")
    ]

    /// Shared interest selection (used across interest screens)
    private var selectedItems: Set<InterestItem> {
        get { InterestSelectionStore.shared.selected }
        set { InterestSelectionStore.shared.selected = newValue }
    }

    // MARK: - Colors
    private let bgSoft = UIColor(hex: "#F4F5F7")
    private let baseCard = UIColor(hex: "#FBF8FF")
    private let selectedCard = UIColor(hex: "#5B3CC4")
    private let baseTint = UIColor(hex: "#333333")
    private let selectedTint = UIColor.white
    private let borderColor = UIColor(hex: "#E6E3EE")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        updateContinueState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContinueState()
        collectionView.reloadData()
    }



    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = bgSoft

        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(hex: "#2E2E2E")

        requirementLabel.font = .systemFont(ofSize: 15)
        requirementLabel.textColor = UIColor(hex: "#6B6B6B")

        showAllButton.layer.cornerRadius = 27
        showAllButton.clipsToBounds = true
        showAllButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        showAllButton.setTitleColor(.white, for: .normal)
        showAllButton.backgroundColor = UIColor(hex: "#5B3CC4")

        continueButton.layer.cornerRadius = 27
        continueButton.clipsToBounds = true
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.setTitleColor(.white, for: .normal)
    }

    // MARK: - Collection View
    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            UINib(nibName: "InterestCard", bundle: nil),
            forCellWithReuseIdentifier: InterestCard.reuseIdentifier
        )

        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 3.0),
                heightDimension: .fractionalHeight(1.0)
            )

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(145)
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item, item, item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 14, leading: 12, bottom: 140, trailing: 12
            )

            return section
        }

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Session Sync

    // MARK: - State
    private func updateContinueState() {
        let enabled = selectedItems.count >= 3

        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled
            ? UIColor(hex: "#5B3CC4")
            : UIColor(hex: "#C9C7D6")

        requirementLabel.text = enabled
            ? "You're all set! Continue now."
            : "Select at least 3 interests to continue"
    }

    // MARK: - Actions

    @IBAction private func showAllTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "InterestsScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard
            selectedItems.count >= 3,
            var user = SessionManager.shared.currentUser
        else { return }

        // Persist interests into session
        user.interests = selectedItems
        SessionManager.shared.updateSessionUser(user)

        goToCommitmentChoice()
    }

    // MARK: - Navigation

    private func goToCommitmentChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CommitmentScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Collection View DataSource & Delegate

extension OnboardingInterestsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        popularItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let item = popularItems[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InterestCard.reuseIdentifier,
            for: indexPath
        ) as! InterestCard

        let isSelected = selectedItems.contains(item)

        cell.configure(
            with: item,
            backgroundColor: isSelected ? selectedCard : baseCard,
            tintColor: isSelected ? selectedTint : baseTint,
            borderColor: borderColor,
            selected: isSelected
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = popularItems[indexPath.item]

        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }

        updateContinueState()
        collectionView.reloadItems(at: [indexPath])
    }
}

