import UIKit

class RoleplaysViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private let searchController = UISearchController(searchResultsController: nil)
    var selectedScenario: RoleplayScenario?
    var selectedSession: RoleplaySession?
    var roleplays: [RoleplayScenario] = []
    var filteredRoleplays: [RoleplayScenario] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        roleplays = RoleplayScenarioDataModel.shared.getAll()
        filteredRoleplays = roleplays

        setupSearchController()
        setupCollectionView()

        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground

        setupProfileBarButton()
    }

    // MARK: - Search Controller (iOS modern style)

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search roleplays"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupProfileBarButton() {
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(openProfile)
        )
        profileButton.tintColor = AppColors.primary
        navigationItem.rightBarButtonItem = profileButton
    }

    @objc private func openProfile() {
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        guard let profileNav = storyboard.instantiateInitialViewController() as? UINavigationController,
              let profileVC = profileNav.viewControllers.first else { return }
        navigationController?.pushViewController(profileVC, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCollectionViewLayout()
    }

    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
    }

    func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()

        let padding: CGFloat = 16
        let spacing: CGFloat = 16

        let totalSpacing = padding * 2 + spacing
        let itemWidth = (collectionView.frame.width - totalSpacing) / 2

        layout.itemSize = CGSize(width: itemWidth, height: 130)
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(
            top: 16,
            left: padding,
            bottom: 20,
            right: padding
        )

        collectionView.collectionViewLayout = layout
    }

    private func filterRoleplays(for searchText: String) {
        if searchText.isEmpty {
            filteredRoleplays = roleplays
        } else {
            filteredRoleplays = roleplays.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }
        collectionView.reloadData()
    }
}

// MARK: - UISearchResultsUpdating

extension RoleplaysViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        filterRoleplays(for: searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchControllerDelegate

extension RoleplaysViewController: UISearchControllerDelegate {

    func didDismissSearchController(_ searchController: UISearchController) {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
}

// MARK: - UICollectionView

extension RoleplaysViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredRoleplays.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RoleplayCell",
            for: indexPath
        ) as! RoleplaysCell

        let scenario = filteredRoleplays[indexPath.row]
        cell.configure(title: scenario.title, imageName: scenario.imageURL)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedScenario = filteredRoleplays[indexPath.row]
        performSegue(withIdentifier: "toRolePlayStart", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRolePlayStart",
           let vc = segue.destination as? RolePlayStartCollectionViewController {
            vc.hidesBottomBarWhenPushed = true
            vc.currentScenario = selectedScenario
        }
    }
}
