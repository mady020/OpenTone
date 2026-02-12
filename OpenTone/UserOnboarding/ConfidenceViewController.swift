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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        updateContinueState()
    }

    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground
        
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor.secondaryLabel
        
        UIHelper.stylePrimaryButton(continueButton)
        
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

    private func updateContinueState() {
        let enabled = selectedOption != nil
        UIHelper.setButtonState(continueButton, enabled: enabled)

        subtitleLabel.text = enabled
            ? "You're all set!"
            : "Select one to continue"
    }

    @IBAction private func continueTapped(_ sender: UIButton) {
        guard
            let option = selectedOption,
            var user = SessionManager.shared.currentUser
        else { return }
        user.confidenceLevel = option
        SessionManager.shared.updateSessionUser(user)

        goToInterestsChoice()
    }

    private func goToInterestsChoice() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "InterestsIntro"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

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
            backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
            textColor: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            borderColor: AppColors.cardBorder
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedOption = options[indexPath.item]
        collectionView.reloadData()
    }
}

