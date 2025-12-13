import UIKit

final class OnboardingInterestsViewController: UIViewController {
    
    var user: User?

    // MARK: - Popular subset (shown on first onboarding screen)
    private let popularItems: [InterestItem] = [
        InterestItem(title: "Technology",   symbol: "cpu"),
        InterestItem(title: "Gaming",       symbol: "gamecontroller.fill"),
        InterestItem(title: "Travel",       symbol: "airplane"),
        InterestItem(title: "Fitness",      symbol: "dumbbell"),
        InterestItem(title: "Food",         symbol: "fork.knife"),
        InterestItem(title: "Music",        symbol: "music.note.list")
    ]

    // MARK: - Selection set
    private var selectedItems: Set<InterestItem> {
        get { InterestSelectionStore.shared.selected }
        set { InterestSelectionStore.shared.selected = newValue }
    }

    // MARK: - UI
    private var collectionView: UICollectionView!
    private let showAllButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Choose your interests"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = UIColor(hex: "#2E2E2E")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let requirementLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Select at least 3 interests to continue"
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = UIColor(hex: "#6B6B6B")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

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
        view.backgroundColor = bgSoft

        addHeaderLabels()
        configureCollectionView()
        configureButtons()
        updateContinueState()
    }

    // MARK: - Header Labels Layout
    private func addHeaderLabels() {
        view.addSubview(titleLabel)
        view.addSubview(requirementLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            requirementLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            requirementLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            requirementLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Collection View (3-column grid)
    private func configureCollectionView() {
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
            section.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 140, trailing: 12)
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(InterestCard.self, forCellWithReuseIdentifier: "interestCard")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: requirementLabel.bottomAnchor, constant: 22),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Buttons
    private func configureButtons() {
        showAllButton.setTitle("Show All Interests", for: .normal)
        showAllButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        showAllButton.tintColor = .white
        showAllButton.backgroundColor = UIColor(hex: "#5B3CC4")
        showAllButton.layer.cornerRadius = 18
        showAllButton.translatesAutoresizingMaskIntoConstraints = false
        showAllButton.addTarget(self, action: #selector(openFullInterests), for: .touchUpInside)

        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.layer.cornerRadius = 18
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        view.addSubview(showAllButton)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            showAllButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            showAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            showAllButton.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -12),
            showAllButton.heightAnchor.constraint(equalToConstant: 54),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            continueButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func updateContinueState() {
        let enabled = selectedItems.count >= 3
        continueButton.isUserInteractionEnabled = enabled
        continueButton.backgroundColor = enabled ? UIColor(hex: "#5B3CC4") : UIColor(hex: "#C9C7D6")
        continueButton.tintColor = .white

        requirementLabel.text = enabled
            ? "You're all set! Continue now."
            : "Select at least 3 interests to continue"
    }

    // MARK: - Actions
    @objc private func openFullInterests() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "InterestsScreen") as! InterestsViewController
        
        vc.user = user
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func continueTapped() {
        guard selectedItems.count >= 3 else { return }
        user?.interests = selectedItems
        goToCommitmentChoice()
    }
    
    private func goToCommitmentChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CommitmentScreen"
        ) as! CommitmentViewController

        vc.user = user
        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - Data Source & Delegate
extension OnboardingInterestsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularItems.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = popularItems[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "interestCard", for: indexPath) as! InterestCard

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
        let item = popularItems[indexPath.row]

        if selectedItems.contains(item) { selectedItems.remove(item) }
        else { selectedItems.insert(item) }

        updateContinueState()
        collectionView.reloadItems(at: [indexPath])
    }
}

