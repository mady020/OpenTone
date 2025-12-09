//
//  HistoryViewController.swift
//  OpenTone
//
//  Created by Student on 08/12/25.
//

import UIKit

class HistoryViewController: UIViewController,UISearchBarDelegate{

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var historyItems: [HistoryItem] = []
    var weekData: [DayProgress] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        view.backgroundColor = .systemBackground
        searchBar.delegate = self
        setupTable()
        loadDummyData()
    }

    func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
    }

    func loadDummyData() {
        historyItems = [
            HistoryItem(title: "2 Min Session",
                        subtitle: "You completed 2 min session",
                        topic: "Time Travel",
                        duration: "2 min",
                        xp: 15,
                        iconName: "mic.fill"),

            HistoryItem(title: "RolePlays",
                        subtitle: "You completed RolePlays session",
                        topic: "Time Travel",
                        duration: "15 min",
                        xp: 15,
                        iconName: "theatermasks.fill"),

            HistoryItem(title: "1 to 1 Call",
                        subtitle: "You completed 1 to 1 call session",
                        topic: "Time Travel",
                        duration: "10 min",
                        xp: 15,
                        iconName: "phone.fill")
        ]
    }
}
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        historyItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "HistoryCell",
            for: indexPath
        ) as! HistoryTableViewCell

        cell.configure(with: historyItems[indexPath.row])
        return cell
    }
}

