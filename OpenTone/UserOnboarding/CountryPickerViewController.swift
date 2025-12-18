import UIKit

struct Country: Hashable, Codable {
    let name: String
    let code: String

    var flag: String {
        code.uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}

class CountryPickerViewController: UIViewController {

    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var tableView: UITableView!

    private var countries: [Country] = Locale.isoRegionCodes.compactMap {
        guard let name = Locale.current.localizedString(forRegionCode: $0) else { return nil }
        return Country(name: name, code: $0)
    }.sorted { $0.name < $1.name }

    private var filtered: [Country] = []

    var onSelect: ((Country) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        filtered = countries
        setupUI()
        setupTable()
        setupActions()
        navigationItem.title = "Select your country"
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        searchField.layer.cornerRadius = 14
        searchField.clipsToBounds = true

        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = AppColors.cardBorder.cgColor

        searchField.backgroundColor = .white
        searchField.font = .systemFont(ofSize: 16)

        // left padding
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        searchField.leftView = padding
        searchField.leftViewMode = .always
    }


    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
    }

    private func setupActions() {
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.delegate = self
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let country = filtered[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = "\(country.flag) \(country.name)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = filtered[indexPath.row]
        dismiss(animated: true) {
            self.onSelect?(country)
        }
    }
}

extension CountryPickerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
