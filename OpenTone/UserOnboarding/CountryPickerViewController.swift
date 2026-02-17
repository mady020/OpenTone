import UIKit

struct Country: Hashable, Codable {
    let name: String
    let code: String
    let flag: String

    init(name: String, code: String) {
        self.name = name
        self.code = code
        // Compute flag from code at initialization
        self.flag = code.uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    // Manual Codable conformance to handle initialization
    enum CodingKeys: String, CodingKey {
        case name, code, flag
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.code = try container.decode(String.self, forKey: .code)
        // Recompute flag from code to ensure consistency
        self.flag = self.code.uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encode(flag, forKey: .flag)
    }
}

class CountryPickerViewController: UIViewController {

    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var tableView: UITableView!

    private var countries: [Country] = Locale.Region.isoRegions
        .filter { $0.identifier.count == 2 }
        .compactMap {
        let code = $0.identifier
        guard let name = Locale.current.localizedString(forRegionCode: code) else { return nil }
        return Country(name: name, code: code)
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
        view.backgroundColor = AppColors.screenBackground

        UIHelper.styleTextField(searchField)
        UIHelper.styleLabels(in: view)
        
        // Custom left padding for search icon space
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        searchField.leftView = padding
        searchField.leftViewMode = .always
        
        tableView.backgroundColor = .clear
        tableView.separatorColor = AppColors.cardBorder
        
        // Navigation Bar Title Styling (In case it's used)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.screenBackground
        appearance.titleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        // Manual Layout Styling for Professional Spacing
        // Find the "Select your country" label and adjust constraints
        view.subviews.forEach { subview in
            if let label = subview as? UILabel, label.text?.lowercased().contains("select") == true {
                // Found the title label
                label.font = .systemFont(ofSize: 20, weight: .bold) // Ensure professional font
                
                // Adjust Top Constraint
                if let topConstraint = view.constraints.first(where: {
                    ($0.firstItem === label && $0.firstAttribute == .top) ||
                    ($0.secondItem === label && $0.secondAttribute == .top)
                }) {
                    topConstraint.constant = 24 // More breathing room at top
                }
                
                // Adjust Bottom Spacing (Top of search field)
                if let searchTop = view.constraints.first(where: {
                    ($0.firstItem === searchField && $0.firstAttribute == .top)
                }) {
                    searchTop.constant = 20 // More space between title and search
                }
            }
        }
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
        cell.backgroundColor = .clear
        cell.textLabel?.text = "\(country.flag) \(country.name)"
        cell.textLabel?.textColor = AppColors.textPrimary
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = AppColors.primary.withAlphaComponent(0.1)
        cell.selectedBackgroundView = selectedBackground
        
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
