import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var items: [HistoryItem] = []
    var selectedDate: Date = Date()

    private let searchController = UISearchController(searchResultsController: nil)
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

        setupSearchController()
        setupNavigation()

        filteredItems = items
        tableView.reloadData()
    }

    private func setupNavigation() {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        navigationItem.title = formatter.string(from: selectedDate)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search your activity"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
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
            startVC.hidesBottomBarWhenPushed = true
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

// MARK: - UISearchResultsUpdating

extension HistoryViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").lowercased()

        filteredItems = text.isEmpty
            ? items
            : items.filter {
                $0.title.lowercased().contains(text) ||
                $0.subtitle.lowercased().contains(text) ||
                $0.topic.lowercased().contains(text)
            }

        tableView.reloadData()
    }
}
