import UIKit

struct CommitmentOption: Hashable {
    let title: String
    let subtitle: String
    let number: Int
}

final class CommitmentViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var continueButton: UIButton!

    private let options: [CommitmentOption] = [
        CommitmentOption(title: "5 minutes per day", subtitle: "Quick daily progress", number: 5),
        CommitmentOption(title: "10 minutes per day", subtitle: "Steady improvement", number: 10),
        CommitmentOption(title: "20 minutes per day", subtitle: "Fast growth", number: 20),
        CommitmentOption(title: "No schedule", subtitle: "I'll practice whenever I want", number: 0)
    ]

    private var selectedOption: CommitmentOption? {
        didSet { updateContinueState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        preloadFromSession()
        updateContinueState()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground
        
        titleLabel.text = "Daily practice commitment"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        
        subtitleLabel.text = "Choose one option to continue"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor.secondaryLabel
        
        continueButton.layer.cornerRadius = 18
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        // Color handled in updateContinueState
        
        UIHelper.styleLabels(in: view)
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
    private func preloadFromSession() {
        guard
            let user = SessionManager.shared.currentUser,
            let streak = user.streak
        else { return }

        selectedOption = options.first { $0.number == streak.commitment }
    }

    private func updateContinueState() {
        let enabled = selectedOption != nil
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled
            ? AppColors.primary
            : UIColor.systemGray4
    }

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard
            let selected = selectedOption,
            var user = SessionManager.shared.currentUser
        else { return }
        user.streak = Streak(
            commitment: selected.number,
            currentCount: 1,
            longestCount: 0
        )

        SessionManager.shared.updateSessionUser(user)
        InterestSelectionStore.shared.selected.removeAll()

        goToDashboard()
    }

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
            backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
            tintColor: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            borderColor: AppColors.cardBorder
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedOption = options[indexPath.item]
        collectionView.reloadData()
    }
}

