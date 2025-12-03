import UIKit

// MARK: - InterestsViewController
final class InterestsViewController: UIViewController {

    // MARK: - All interests
    private let items: [InterestItem] = [
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

    // MARK: - Shared selection storage
    private var selectedInterests: Set<InterestItem> {
        get { InterestSelectionStore.shared.selected }
        set { InterestSelectionStore.shared.selected = newValue }
    }

    // MARK: - UI
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private let continueButton = UIButton(type: .system)

    // MARK: - Colors
    private let screenBackground  = UIColor(hex: "#F4F5F7")
    private let baseCardColor     = UIColor(hex: "#FBF8FF")
    private let selectedCardColor = UIColor(hex: "#5B3CC4")
    private let normalTint        = UIColor(hex: "#333333")
    private let selectedTint      = UIColor.white
    private let cardBorderColor   = UIColor(hex: "#E6E3EE")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = screenBackground

        configureSearchBar()
        configureCollectionView()
        configureContinueButton()
        updateContinueState()
    }

    // MARK: - Search Bar
    private func configureSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search Interests"
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        searchBar.searchTextField.backgroundColor = UIColor(hex: "#F7F5FB")
        searchBar.searchTextField.textColor = normalTint
        searchBar.searchTextField.layer.cornerRadius = 18
        searchBar.searchTextField.layer.masksToBounds = true

        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Collection View (3-column grid)
    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 3.0), // 3 per row
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
            section.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 12, bottom: 110, trailing: 12)
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(InterestCard.self, forCellWithReuseIdentifier: InterestCard.reuseIdentifier)

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
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

    // Hide button until 3 selected
    private func updateContinueState() {
        let enabled = selectedInterests.count >= 3
        continueButton.isHidden = !enabled
        continueButton.isUserInteractionEnabled = enabled
        continueButton.backgroundColor = enabled ? UIColor(hex: "#5B3CC4") : UIColor(hex: "#C9C7D6")
        continueButton.tintColor = .white
    }

    @objc private func continueTapped() {
        guard selectedInterests.count >= 3 else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        tabBarVC.modalPresentationStyle = .fullScreen
        self.view.window?.rootViewController = tabBarVC
        self.view.window?.makeKeyAndVisible()
    }
}

// MARK: - UICollectionViewDataSource
extension InterestsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InterestCard.reuseIdentifier, for: indexPath
        ) as? InterestCard else { return UICollectionViewCell() }

        let item = items[indexPath.row]
        let isSelected = selectedInterests.contains(item)
        let bgColor = isSelected ? selectedCardColor : baseCardColor
        let tint = isSelected ? selectedTint : normalTint

        cell.configure(with: item, backgroundColor: bgColor, tintColor: tint, borderColor: cardBorderColor, selected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension InterestsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if selectedInterests.contains(item) { selectedInterests.remove(item) }
        else { selectedInterests.insert(item) }
        updateContinueState()
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - InterestCard
final class InterestCard: UICollectionViewCell {

    static let reuseIdentifier = "InterestCard"

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalToConstant: 52),
            iv.widthAnchor.constraint(equalToConstant: 52)
        ])
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [iconView, titleLabel])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 18
        v.layer.masksToBounds = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(stack)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        applyShadow()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: InterestItem,
                   backgroundColor: UIColor,
                   tintColor: UIColor,
                   borderColor: UIColor,
                   selected: Bool) {
        iconView.image = UIImage(systemName: item.symbol)
        iconView.tintColor = tintColor
        titleLabel.text = item.title
        titleLabel.textColor = tintColor
        containerView.backgroundColor = backgroundColor

        containerView.layer.borderWidth = selected ? 0 : 1
        containerView.layer.borderColor = borderColor.cgColor

        containerView.layer.shadowOpacity = selected ? 0.18 : 0.08
        containerView.layer.shadowRadius = selected ? 10 : 6

        UIView.animate(withDuration: 0.18) {
            self.containerView.transform = selected ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
        }
    }

    private func applyShadow() {
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 6
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.transform = .identity
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 6
    }
}

// MARK: - UIColor Hex
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

