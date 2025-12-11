//
//  HistoryViewController.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    // Full dataset
    var items: [HistoryItem] = []
    // Filtered for search
    private var filteredItems: [HistoryItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // TableView setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        // Search setup
        searchBar.delegate = self
        searchBar.placeholder = "Search history (title, topic, duration...)"

        // Sample data if none provided
        if items.isEmpty {
            items = Self.sampleData()
        }
        filteredItems = items

        // Reload safely
        tableView.reloadData()
    }

    // Sample data
    static func sampleData() -> [HistoryItem] {
        return [
            HistoryItem(title: "2 Min Session",
                        subtitle: "You completed 2 min session",
                        topic: "Time Travel",
                        duration: "2 min",
                        xp: "15 XP",
                        iconName: "mic.fill"),
            HistoryItem(title: "RolePlays",
                        subtitle: "You completed RolePlays session",
                        topic: "Interview Practice",
                        duration: "15 min",
                        xp: "25 XP",
                        iconName: "theatermasks.fill"),
            HistoryItem(title: "1 to 1 Call",
                        subtitle: "You completed 1 to 1 call session",
                        topic: "Mock Interview",
                        duration: "10 min",
                        xp: "20 XP",
                        iconName: "phone.fill")
        ]
    }
}

// MARK: - TableView DataSource & Delegate
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Safe dequeue
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? HistoryTableViewCell {
            let item = filteredItems[indexPath.row]
            cell.configure(with: item)
            cell.selectionStyle = .none
            return cell
        } else {
            // Fallback to default cell if something wrong in storyboard
            let fallbackCell = UITableViewCell(style: .subtitle, reuseIdentifier: "FallbackCell")
            let item = filteredItems[indexPath.row]
            fallbackCell.textLabel?.text = item.title
            fallbackCell.detailTextLabel?.text = item.subtitle
            fallbackCell.selectionStyle = .none
            return fallbackCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.row]
        let message = """
        \(item.subtitle)
        Topic: \(item.topic)
        Duration: \(item.duration)
        XP: \(item.xp)
        """
        let alert = UIAlertController(title: item.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension HistoryViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContent(for: searchText)
    }

    func filterContent(for searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filteredItems = items
        } else {
            let lower = trimmed.lowercased()
            filteredItems = items.filter {
                $0.title.lowercased().contains(lower) ||
                $0.subtitle.lowercased().contains(lower) ||
                $0.topic.lowercased().contains(lower) ||
                $0.duration.lowercased().contains(lower) ||
                $0.xp.lowercased().contains(lower)
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
