import UIKit

class RoleplaysViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!

    // Data from your DataModel
    var roleplays: [RoleplayScenario] = []
    var filteredRoleplays: [RoleplayScenario] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load scenarios
        roleplays = RoleplayScenarioDataModel.shared.getAll()
        filteredRoleplays = roleplays

        setupSearchBar()
        setupCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCollectionViewLayout()
    }

    // MARK: - UI Setup
    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search roleplays"
        searchBar.searchBarStyle = .minimal
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true
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
}


// MARK: - CollectionView
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

        let scenario = filteredRoleplays[indexPath.row]
        print("Selected Roleplay:", scenario.title)

        guard let newSession = RoleplaySessionDataModel.shared.startSession(scenarioId: scenario.id) else {
            print("Failed to start session")
            return
        }

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "RoleplayStartVC") as? RolePlayStartCollectionViewController {
            vc.currentScenario = scenario
            vc.currentSession = newSession
        }
    }
}


// MARK: - Search Bar
extension RoleplaysViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            filteredRoleplays = roleplays
        } else {
            filteredRoleplays = roleplays.filter {
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }

        collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @IBAction func unwindToRoleplaysVC(_ segue: UIStoryboardSegue) {
        print("Returned to Roleplays screen")
    }
}
