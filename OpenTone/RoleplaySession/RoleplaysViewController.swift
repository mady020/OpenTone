import UIKit

class RoleplaysViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!

    var roleplays: [String] = [
        "Grocery Shopping",
        "Making Friends",
        "Airport Check-in",
        "Ordering Food",
        "Job Interview",
        "Birthday Celebration",
        "Hotel Booking",
        "First Date"
    ]

    var filteredRoleplays: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        filteredRoleplays = roleplays

        setupSearchBar()
        setupCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCollectionViewLayout()
    }

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

        let title = filteredRoleplays[indexPath.row]
        let imageName = title.replacingOccurrences(of: " ", with: "")

        cell.configure(title: title, imageName: imageName)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected:", filteredRoleplays[indexPath.row])
    }
}

extension RoleplaysViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            filteredRoleplays = roleplays
        } else {
            filteredRoleplays = roleplays.filter {
                $0.lowercased().contains(searchText.lowercased())
            }
        }

        collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    @IBAction func unwindToRoleplaysVC(_ segue: UIStoryboardSegue) {
        // You can write code here if needed
        print("Unwound to First View Controller")
    }

}
