import UIKit

struct ConfidenceOption: Hashable, Codable {
    let title: String
    let emoji: String
}

final class ConfidenceViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var continueButton: UIButton!

    private let options: [ConfidenceOption] = [
        ConfidenceOption(title: "Very Confident", emoji: "💪"),
        ConfidenceOption(title: "Somewhat Confident", emoji: "🙂"),
        ConfidenceOption(title: "Nervous but Trying", emoji: "😬"),
        ConfidenceOption(title: "Very Nervous", emoji: "🥺")
    ]

    private var selectedOption: ConfidenceOption? {
        didSet { updateContinueState() }
    }

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

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = bgSoft

        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(hex: "#2E2E2E")

        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor(hex: "#6B6B6B")

        continueButton.layer.cornerRadius = 27
        continueButton.clipsToBounds = true
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
                heightDimension: .absolute(88)
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

   

    // MARK: - State Handling

    private func updateContinueState() {
        let enabled = selectedOption != nil
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled
            ? UIColor(hex: "#5B3CC4")
            : UIColor(hex: "#C9C7D6")

        subtitleLabel.text = enabled
            ? "You're all set!"
            : "Select one to continue"
    }

    // MARK: - Actions

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard
            let option = selectedOption,
            var user = SessionManager.shared.currentUser
        else { return }

        // Update session user
        user.confidenceLevel = option
        SessionManager.shared.updateSessionUser(user)

        goToInterestsChoice()
    }

    // MARK: - Navigation

    private func goToInterestsChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "InterestsIntro"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Collection View

extension ConfidenceViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let option = options[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "confidenceCard",
            for: indexPath
        ) as! ConfidenceCard

        let isSelected = option == selectedOption

        cell.configure(
            option: option,
            backgroundColor: isSelected ? selectedCard : baseCard,
            textColor: isSelected ? selectedTint : baseTint,
            borderColor: borderColor
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedOption = options[indexPath.item]
        collectionView.reloadData()
    }
}

