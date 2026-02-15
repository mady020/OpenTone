import UIKit

/// Settings screen with theme toggle, account info, and logout.
/// Fully programmatic — no storyboard required. HIG-compliant grouped table view.
final class SettingsViewController: UIViewController {

    // MARK: - Data Model

    private enum Section: Int, CaseIterable {
        case appearance
        case apiKeys
        case account
        case about
        case actions
    }

    private struct Row {
        let title: String
        let icon: String
        let iconTint: UIColor
        var detail: String?
        var isDestructive: Bool = false
    }

    private var sections: [[Row]] = []

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tv.backgroundColor = AppColors.screenBackground
        tv.separatorColor = AppColors.cardBorder
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = AppColors.screenBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        buildSections()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildSections()
        tableView.reloadData()
    }

    // MARK: - Setup

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buildSections() {
        let themeName = ThemeManager.shared.currentTheme.title

        let user = SessionManager.shared.currentUser

        let geminiDetail = GeminiAPIKeyManager.shared.maskedKey ?? "Not configured"

        sections = [
            // Section 0 — Appearance
            [
                Row(title: "Theme", icon: "paintbrush.fill", iconTint: AppColors.primary, detail: themeName)
            ],
            // Section 1 — API Keys
            [
                Row(title: "Gemini API Key", icon: "key.fill", iconTint: .systemYellow, detail: geminiDetail)
            ],
            // Section 2 — Account
            [
                Row(title: "Name", icon: "person.fill", iconTint: .systemBlue, detail: user?.name ?? "—"),
                Row(title: "Email", icon: "envelope.fill", iconTint: .systemTeal, detail: user?.email ?? "—"),
                Row(title: "Country", icon: "globe", iconTint: .systemGreen,
                    detail: user?.country.map { "\($0.flag) \($0.name)" } ?? "—"),
                Row(title: "English Level", icon: "text.book.closed.fill", iconTint: .systemOrange,
                    detail: user?.englishLevel?.rawValue.capitalized ?? "—")
            ],
            // Section 2 — About
            [
                Row(title: "Version", icon: "info.circle.fill", iconTint: .secondaryLabel, detail: appVersion),
                Row(title: "Privacy Policy", icon: "hand.raised.fill", iconTint: .systemIndigo),
                Row(title: "Terms of Service", icon: "doc.text.fill", iconTint: .systemIndigo)
            ],
            // Section 3 — Actions
            [
                Row(title: "Log Out", icon: "rectangle.portrait.and.arrow.right", iconTint: .systemRed, isDestructive: true)
            ]
        ]
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private func showThemePicker() {
        let alert = UIAlertController(title: "Choose Theme", message: nil, preferredStyle: .actionSheet)

        for theme in ThemeManager.Theme.allCases {
            let action = UIAlertAction(title: theme.title, style: .default) { [weak self] _ in
                ThemeManager.shared.currentTheme = theme
                self?.buildSections()
                self?.tableView.reloadData()
            }
            if theme == ThemeManager.shared.currentTheme {
                action.setValue(true, forKey: "checked")
            }
            let iconImage = UIImage(systemName: theme.iconName)
            action.setValue(iconImage, forKey: "image")
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func confirmLogout() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func showGeminiAPIKeyEditor() {
        let hasKey = GeminiAPIKeyManager.shared.hasAPIKey
        let title = hasKey ? "Update Gemini API Key" : "Add Gemini API Key"
        let message = "Enter your Gemini API key from Google AI Studio.\nYour key is stored securely in the iOS Keychain."

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { tf in
            tf.placeholder = "AIza..."
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
            tf.isSecureTextEntry = true
            tf.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let key = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !key.isEmpty else { return }
            GeminiAPIKeyManager.shared.setAPIKey(key)
            self?.buildSections()
            self?.tableView.reloadData()
        })

        if hasKey {
            alert.addAction(UIAlertAction(title: "Remove Key", style: .destructive) { [weak self] _ in
                GeminiAPIKeyManager.shared.deleteAPIKey()
                self?.buildSections()
                self?.tableView.reloadData()
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func performLogout() {
        SessionManager.shared.logout()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController(),
              let window = view.window else { return }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = vc
        }
        window.makeKeyAndVisible()
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .appearance: return "Appearance"
        case .apiKeys:    return "Integrations"
        case .account:    return "Account"
        case .about:      return "About"
        case .actions:    return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        let row = sections[indexPath.section][indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.textProperties.color = row.isDestructive ? .systemRed : AppColors.textPrimary
        content.textProperties.font = .systemFont(ofSize: 17, weight: row.isDestructive ? .medium : .regular)

        content.secondaryText = row.detail
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = .systemFont(ofSize: 15)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        content.image = UIImage(systemName: row.icon, withConfiguration: iconConfig)
        content.imageProperties.tintColor = row.isDestructive ? .systemRed : row.iconTint

        cell.contentConfiguration = content
        cell.backgroundColor = AppColors.cardBackground
        cell.selectionStyle = row.isDestructive || row.detail == nil || indexPath.section == 0 ? .default : .none

        // Show disclosure for actionable rows
        let section = Section(rawValue: indexPath.section)
        if section == .appearance || section == .apiKeys || section == .actions || (section == .about && indexPath.row > 0) {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .appearance:
            showThemePicker()

        case .apiKeys:
            showGeminiAPIKeyEditor()

        case .account:
            break // Read-only for now

        case .about:
            if indexPath.row == 1 || indexPath.row == 2 {
                // Placeholder for Privacy Policy / Terms
                let alert = UIAlertController(
                    title: sections[indexPath.section][indexPath.row].title,
                    message: "This feature will be available soon.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }

        case .actions:
            confirmLogout()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50 // HIG minimum 44pt touch target + padding
    }
}
