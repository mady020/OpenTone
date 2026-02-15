
import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var items: [HistoryItem] = []
    var selectedDate: Date = Date()

    private var filteredItems: [HistoryItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground
        tableView.backgroundColor = AppColors.screenBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none

        searchBar.delegate = self
        searchBar.placeholder = "Search your activity"
        searchBar.barTintColor = AppColors.screenBackground
        searchBar.tintColor = AppColors.primary

        filteredItems = items
        tableView.reloadData()
        updateTitle()
    }

    private func updateTitle() {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        navigationItem.title = formatter.string(from: selectedDate)
    }

    // MARK: - Resume Sessions

    private func resumeRoleplaySession(scenarioId: UUID) {
        // Check if there's a saved session for this scenario
        if let saved = RoleplaySessionDataModel.shared.getSavedSession(),
           saved.scenarioId == scenarioId,
           let (session, scenario) = RoleplaySessionDataModel.shared.resumeSavedSession() {

            let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
            guard let chatVC = storyboard.instantiateViewController(
                withIdentifier: "RoleplayChatVC"
            ) as? RoleplayChatViewController else { return }

            chatVC.scenario = scenario
            chatVC.session = session
            chatVC.entryPoint = .dashboard

            navigationController?.pushViewController(chatVC, animated: true)
        } else {
            // Start a fresh session for this scenario
            guard let scenario = RoleplayScenarioDataModel.shared.getScenario(by: scenarioId) else { return }

            let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
            guard let startVC = storyboard.instantiateViewController(
                withIdentifier: "RolePlayStartVC"
            ) as? RolePlayStartCollectionViewController else { return }

            startVC.currentScenario = scenario
            navigationController?.pushViewController(startVC, animated: true)
        }
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
        cell.selectionStyle = item.scenarioId != nil ? .default : .none
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = filteredItems[indexPath.row]
        if let scenarioId = item.scenarioId {
            resumeRoleplaySession(scenarioId: scenarioId)
        }
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
