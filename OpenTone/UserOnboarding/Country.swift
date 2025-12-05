//
//  Country.swift
//  OpenTone
//
//  Created by M S on 05/12/25.
//


import UIKit

struct Country: Hashable {
    let name: String
    let code: String
    var flag: String {
        code.uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func codeToFlag(_ code: String) -> [Int] {
        code.uppercased().unicodeScalars.map { 127397 + Int($0.value) }
    }
}

final class CountryPickerViewController: UIViewController {

    private var countries: [Country] = Locale.isoRegionCodes.compactMap {
        guard let name = Locale.current.localizedString(forRegionCode: $0) else { return nil }
        return Country(name: name, code: $0)
    }.sorted { $0.name < $1.name }

    private var filtered: [Country] = []
    var onSelect: ((Country) -> Void)?

    private let searchField = UITextField()
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        filtered = countries

        setupSearch()
        setupTable()
    }

    private func setupSearch() {
        searchField.placeholder = "Search country"
        searchField.borderStyle = .roundedRect
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        view.addSubview(searchField)
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func searchChanged() {
        let text = searchField.text?.lowercased() ?? ""
        filtered = text.isEmpty
            ? countries
            : countries.filter { $0.name.lowercased().contains(text) }
        tableView.reloadData()
    }
}

extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ctry = filtered[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = "\(ctry.flag) \(ctry.name)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = filtered[indexPath.row]
        dismiss(animated: true) { self.onSelect?(c) }
    }
}
