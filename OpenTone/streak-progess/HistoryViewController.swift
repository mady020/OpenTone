
import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
        var items: [HistoryItem] = []
        var selectedDate: Date = Date()

        private var filteredItems: [HistoryItem] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 100

            searchBar.delegate = self
            searchBar.placeholder = "Search your activity"

            filteredItems = items
            tableView.reloadData()
            updateTitle()
        }

        private func updateTitle() {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            navigationItem.title = formatter.string(from: selectedDate)
        }
    }

    extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            filteredItems.count
        }

        func tableView(
            _ tableView: UITableView,
            cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {

            let item = filteredItems[indexPath.row]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "HistoryCell",
                for: indexPath
            ) as! HistoryTableViewCell

            cell.configure(with: item)
            cell.selectionStyle = .none
            return cell
        }
    }

    extension HistoryViewController: UISearchBarDelegate {

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            let text = searchText.lowercased()

            filteredItems = text.isEmpty
                ? items
                : items.filter {
                    $0.title.lowercased().contains(text) ||
                    $0.subtitle.lowercased().contains(text) ||
                    $0.topic.lowercased().contains(text)
                }

            tableView.reloadData()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
