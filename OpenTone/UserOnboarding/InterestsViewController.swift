import UIKit

final class InterestsViewController: UIViewController {

    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var continueButton: UIButton!

    private let allItems: [InterestItem] = [
        InterestItem(title: "Technology",   symbol: "cpu"),
        InterestItem(title: "Gaming",       symbol: "gamecontroller.fill"),
        InterestItem(title: "Travel",       symbol: "airplane"),
        InterestItem(title: "Fitness",      symbol: "dumbbell"),
        InterestItem(title: "Food",         symbol: "fork.knife"),
        InterestItem(title: "Music",        symbol: "music.note.list"),
        InterestItem(title: "Movies",       symbol: "film.fill"),
        InterestItem(title: "Photography",  symbol: "camera.fill"),
        InterestItem(title: "Finance",      symbol: "chart.bar.xaxis"),
        InterestItem(title: "Business",     symbol: "briefcase.fill"),
        InterestItem(title: "Health",       symbol: "heart.fill"),
        InterestItem(title: "Learning",     symbol: "book.fill"),
        InterestItem(title: "Productivity", symbol: "checkmark.circle"),
        InterestItem(title: "Shopping",     symbol: "cart.fill"),
        InterestItem(title: "Sports",       symbol: "sportscourt.fill"),
        InterestItem(title: "Cars",         symbol: "car.fill"),
        InterestItem(title: "Cooking",      symbol: "takeoutbag.and.cup.and.straw.fill"),
        InterestItem(title: "Fashion",      symbol: "tshirt.fill"),
        InterestItem(title: "Pets",         symbol: "pawprint.fill"),
        InterestItem(title: "Art & Design", symbol: "paintpalette.fill")
    ]

    private var filteredItems: [InterestItem] = []
    private var selectedInterests: Set<InterestItem> {
        get { InterestSelectionStore.shared.selected }
        set { InterestSelectionStore.shared.selected = newValue }
    }
    
    private let borderColor       = AppColors.cardBorder

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground
        filteredItems = allItems

        setupSearchBar()
        setupCollectionView()
        setupContinueButton()
        updateContinueState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContinueState()
        collectionView.reloadData()
    }

    private func setupSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search Interests"
        searchBar.delegate = self
        
        // Style the search field
        if let tf = searchBar.value(forKey: "searchField") as? UITextField {
            tf.backgroundColor = AppColors.cardBackground
            tf.textColor = AppColors.textPrimary
            tf.layer.cornerRadius = 18
            tf.layer.masksToBounds = true
            
            // Placeholder color
            let placeholderColor = UIColor.secondaryLabel
            let validText = tf.placeholder ?? ""
            tf.attributedPlaceholder = NSAttributedString(
                string: validText,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
            
            // Icon color
            if let leftView = tf.leftView as? UIImageView {
                leftView.tintColor = UIColor.secondaryLabel
            }
        }
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            UINib(nibName: "InterestCard", bundle: nil),
            forCellWithReuseIdentifier: InterestCard.reuseIdentifier
        )

        collectionView.collectionViewLayout = makeLayout()
    }

    private func setupContinueButton() {
        UIHelper.stylePrimaryButton(continueButton)
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in

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
                top: 18, leading: 12, bottom: 110, trailing: 12
            )

            return section
        }
    }

    private func updateContinueState() {
        let enabled = selectedInterests.count >= 3
        continueButton.isHidden = !enabled
        UIHelper.setButtonState(continueButton, enabled: enabled)
    }

    @IBAction private func continueTapped() {
        guard
            selectedInterests.count >= 3,
            var user = SessionManager.shared.currentUser
        else { return }
        user.interests = selectedInterests
        SessionManager.shared.updateSessionUser(user)

        goToCommitment()
    }

    private func goToCommitment() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CommitmentScreen"
        )

        navigationController?.pushViewController(vc, animated: true)
    }
}

extension InterestsViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InterestCard.reuseIdentifier,
            for: indexPath
        ) as! InterestCard

        let item = filteredItems[indexPath.item]
        let isSelected = selectedInterests.contains(item)

        cell.configure(
            with: item,
            backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
            tintColor: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            borderColor: borderColor,
            selected: isSelected
        )

        return cell
    }
}

extension InterestsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.item]

        if selectedInterests.contains(item) {
            selectedInterests.remove(item)
        } else {
            selectedInterests.insert(item)
        }

        updateContinueState()
        collectionView.reloadItems(at: [indexPath])
    }
}

extension InterestsViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        filteredItems = query.isEmpty
            ? allItems
            : allItems.filter { $0.title.lowercased().contains(query) }

        collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


// UIColor(hex:) extension is defined in Utils/UIColor+Hex.swift
