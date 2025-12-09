import UIKit

struct CommitmentOption: Hashable {
    let title: String
    let subtitle: String
    let number: Int
}

final class CommitmentViewController: UIViewController {

    var user: User?
    // MARK: - Data
    private let options: [CommitmentOption] = [
        CommitmentOption(title: "5 minutes per day", subtitle: "Quick daily progress", number: 5),
        CommitmentOption(title: "10 minutes per day", subtitle: "Steady improvement", number: 10),
        CommitmentOption(title: "20 minutes per day", subtitle: "Fast growth", number: 20),
        CommitmentOption(title: "No schedule", subtitle: "I'll practice whenever I want", number: 0)
    ]

    private var selectedOption: CommitmentOption? = nil

    // MARK: - UI
    private var collectionView: UICollectionView!
    private let continueButton = UIButton(type: .system)

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Daily practice commitment"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = UIColor(hex: "#2E2E2E")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Choose one option to continue"
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgSoft

        addHeader()
        configureCollectionView()
        configureContinueButton()
        updateContinueState()
    }

    // MARK: - Header
    private func addHeader() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - CollectionView (full-width cards)
    private func configureCollectionView() {
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
                subitem: item,
                count: 1
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 14
            section.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 140, trailing: 16)
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(CommitmentCard.self, forCellWithReuseIdentifier: "commitmentCard")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 22),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Continue Button
    private func configureContinueButton() {
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.layer.cornerRadius = 18
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            continueButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func updateContinueState() {
        let enabled = selectedOption != nil
        continueButton.isUserInteractionEnabled = enabled
        continueButton.backgroundColor = enabled ? selectedCard : UIColor(hex: "#C9C7D6")
        continueButton.tintColor = .white
        subtitleLabel.text = enabled ? "Great! Continue now." : "Choose one option to continue"
    }
    private func goToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        print(user ?? "nil")
        tabBarVC.user = user
        tabBarVC.modalPresentationStyle = .fullScreen
        tabBarVC.modalTransitionStyle = .crossDissolve
        self.view.window?.rootViewController = tabBarVC
        self.view.window?.makeKeyAndVisible()
    }
    
    // MARK: - Next Step
    @objc private func continueTapped() {
        guard let selected = selectedOption else { return }
        user?.streak?.commitment = selected.number
        goToDashboard()
    }
}

// MARK: - Data Source + Delegate
extension CommitmentViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let option = options[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commitmentCard", for: indexPath) as! CommitmentCard
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
        selectedOption = options[indexPath.row]
        updateContinueState()
        collectionView.reloadData()
    }
}

