import UIKit

final class OnboardingInterestsViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var requirementLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var showAllButton: UIButton!
    @IBOutlet private weak var continueButton: UIButton!

    private let popularItems = InterestItem.popularItems
    private var selectedItems: Set<InterestItem> {
        get { InterestSelectionStore.shared.selected }
        set { InterestSelectionStore.shared.selected = newValue }
    }

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
    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground

        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary

        requirementLabel.font = .systemFont(ofSize: 15)
        requirementLabel.textColor = UIColor.secondaryLabel

        // Show All Button
        UIHelper.stylePrimaryButton(showAllButton)
        // Ensure consistent corner radius if needed, UIHelper uses 25 (pill)
        // This view controller used 27. Let's stick to UIHelper's standard or override if needed.
        // User liked rounded buttons. UIHelper.stylePrimaryButton does pill shape.
        
        UIHelper.stylePrimaryButton(continueButton)
        
        UIHelper.styleLabels(in: view)
    }
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
    private func updateContinueState() {
        let enabled = selectedItems.count >= 3

        UIHelper.setButtonState(continueButton, enabled: enabled)

        requirementLabel.text = enabled
            ? "You're all set! Continue now."
            : "Select at least 3 interests to continue"
    }

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
        user.interests = selectedItems
        SessionManager.shared.updateSessionUser(user)

        goToCommitmentChoice()
    }

    private func goToCommitmentChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CommitmentScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

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
            backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
            tintColor: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            borderColor: AppColors.cardBorder,
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

