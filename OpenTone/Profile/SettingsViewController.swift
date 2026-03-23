import UIKit

/// Settings screen with theme toggle, account info, and logout.
/// Fully programmatic — no storyboard required. HIG-compliant grouped table view.
final class SettingsViewController: UIViewController {

    // MARK: - Data Model

    private enum Section: Int, CaseIterable {
        case appearance
        case feedback
        case account
        case about
        case actions
        case dangerZone
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

        sections = [
            // Section 0 — Appearance
            [
                Row(title: "Theme", icon: "paintbrush.fill", iconTint: AppColors.primary, detail: themeName)
            ],
            // Section 1 — Feedback
            [
                Row(title: "AI-Enabled Feedback", icon: "sparkles", iconTint: .systemPurple, detail: isAIFeedbackEnabled() ? "On" : "Off")
            ],
            // Section 2 — Account
            [
                Row(title: "Email", icon: "envelope.fill", iconTint: .systemBlue, detail: user?.email ?? "—"),
                Row(title: "Password", icon: "lock.fill", iconTint: .systemOrange, detail: "••••••••")
            ],
            // Section 3 — About
            [
                Row(title: "Version", icon: "info.circle.fill", iconTint: .secondaryLabel, detail: appVersion),
                Row(title: "Privacy Policy", icon: "hand.raised.fill", iconTint: .systemIndigo),
                Row(title: "Terms of Service", icon: "doc.text.fill", iconTint: .systemIndigo)
            ],
            // Section 4 — Actions
            [
                Row(title: "Log Out", icon: "rectangle.portrait.and.arrow.right", iconTint: .systemRed, isDestructive: true)
            ],
            // Section 5 — Danger Zone
            [
                Row(title: "Delete Account", icon: "trash.fill", iconTint: .systemRed, isDestructive: true)
            ]
        ]
    }

    private func isAIFeedbackEnabled() -> Bool {
        SessionManager.shared.currentUser?.aiFeedbackEnabled ?? false
    }

    private func setAIFeedbackEnabled(_ enabled: Bool) {
        guard var user = SessionManager.shared.currentUser else { return }
        user.aiFeedbackEnabled = enabled
        SessionManager.shared.updateSessionUser(user)
        buildSections()
        tableView.reloadData()
    }

    @objc private func aiFeedbackSwitchChanged(_ sender: UISwitch) {
        setAIFeedbackEnabled(sender.isOn)
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

    private func performLogout() {
        Task { @MainActor in
            await SessionManager.shared.logoutAsync()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateInitialViewController(),
                  let window = self.view.window else { return }

            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = vc
            }
            window.makeKeyAndVisible()
        }
    }

    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This will permanently delete your account and all your data including call records, roleplay sessions, jam sessions, and streak progress. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            // Second confirmation
            let confirm = UIAlertController(
                title: "Are you absolutely sure?",
                message: "Type DELETE to confirm account deletion.",
                preferredStyle: .alert
            )
            confirm.addTextField { tf in
                tf.placeholder = "Type DELETE"
                tf.autocapitalizationType = .allCharacters
            }
            confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirm.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let text = confirm.textFields?.first?.text, text == "DELETE" else {
                    let error = UIAlertController(
                        title: "Deletion Cancelled",
                        message: "You must type DELETE to confirm.",
                        preferredStyle: .alert
                    )
                    error.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(error, animated: true)
                    return
                }
                self?.performDeleteAccount()
            })
            self?.present(confirm, animated: true)
        })
        present(alert, animated: true)
    }

    private func performDeleteAccount() {
        // Delete all user data
        UserDataModel.shared.deleteCurrentUser()
        SessionManager.shared.logout()

        // Clear related data
        StreakDataModel.shared.deleteStreak()
        HistoryDataModel.shared.clearHistory()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController(),
              let window = view.window else { return }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = vc
        }
        window.makeKeyAndVisible()
    }

    private func showEditField(for row: Int) {
        guard var user = SessionManager.shared.currentUser else { return }

        switch row {
        case 0: // Email
            showTextEditor(title: "Update Email", current: user.email, keyboardType: .emailAddress) { newValue in
                user.email = newValue
                SessionManager.shared.updateSessionUser(user)
                self.buildSections()
                self.tableView.reloadData()
            }
        case 1: // Password
            showPasswordEditor()
        default:
            break
        }
    }

    private func showPasswordEditor() {
        guard let user = SessionManager.shared.currentUser else { return }

        let alert = UIAlertController(title: "Update Password", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Current password"
            tf.isSecureTextEntry = true
        }
        alert.addTextField { tf in
            tf.placeholder = "New password"
            tf.isSecureTextEntry = true
        }
        alert.addTextField { tf in
            tf.placeholder = "Confirm new password"
            tf.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            let current = alert.textFields?[0].text ?? ""
            let newPass = alert.textFields?[1].text ?? ""
            let confirm = alert.textFields?[2].text ?? ""

            guard !current.isEmpty, !newPass.isEmpty else {
                self?.showAlert(title: "Error", message: "All fields are required.")
                return
            }
            guard newPass.count >= 6 else {
                self?.showAlert(title: "Error", message: "New password must be at least 6 characters.")
                return
            }
            guard newPass == confirm else {
                self?.showAlert(title: "Error", message: "New passwords do not match.")
                return
            }

            Task { @MainActor in
                do {
                    try await SupabaseAuth.updatePassword(
                        email: user.email,
                        currentPassword: current,
                        newPassword: newPass
                    )
                    self?.showAlert(title: "Success", message: "Password updated successfully.")
                } catch {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showTextEditor(title: String, current: String, keyboardType: UIKeyboardType = .default, onSave: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = current
            tf.clearButtonMode = .whileEditing
            tf.keyboardType = keyboardType
            tf.autocapitalizationType = keyboardType == .emailAddress ? .none : .words
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let newValue = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newValue.isEmpty else { return }
            onSave(newValue)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showCountryPicker() {
        let countries = [
            Country(name: "India", code: "IN"),
            Country(name: "United States", code: "US"),
            Country(name: "United Kingdom", code: "GB"),
            Country(name: "Canada", code: "CA"),
            Country(name: "Australia", code: "AU"),
            Country(name: "Germany", code: "DE"),
            Country(name: "France", code: "FR"),
            Country(name: "Japan", code: "JP"),
            Country(name: "Brazil", code: "BR"),
            Country(name: "Mexico", code: "MX"),
            Country(name: "South Korea", code: "KR"),
            Country(name: "Italy", code: "IT"),
            Country(name: "Spain", code: "ES"),
            Country(name: "Netherlands", code: "NL"),
            Country(name: "Singapore", code: "SG"),
        ]

        let alert = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)
        for country in countries {
            alert.addAction(UIAlertAction(title: "\(country.flag) \(country.name)", style: .default) { [weak self] _ in
                guard var user = SessionManager.shared.currentUser else { return }
                user.country = country
                SessionManager.shared.updateSessionUser(user)
                self?.buildSections()
                self?.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func showEnglishLevelPicker() {
        let alert = UIAlertController(title: "English Level", message: nil, preferredStyle: .actionSheet)
        for level in [EnglishLevel.beginner, .intermediate, .advanced] {
            let action = UIAlertAction(title: level.rawValue.capitalized, style: .default) { [weak self] _ in
                guard var user = SessionManager.shared.currentUser else { return }
                user.englishLevel = level
                SessionManager.shared.updateSessionUser(user)
                self?.buildSections()
                self?.tableView.reloadData()
            }
            if level == SessionManager.shared.currentUser?.englishLevel {
                action.setValue(true, forKey: "checked")
            }
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
        case .feedback:   return "Feedback"
        case .account:    return "Account"
        case .about:      return "About"
        case .actions:    return nil
        case .dangerZone: return "Danger Zone"
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
        cell.selectionStyle = row.isDestructive || row.detail == nil || indexPath.section == Section.appearance.rawValue ? .default : .none

        if Section(rawValue: indexPath.section) == .feedback, indexPath.row == 0 {
            let toggle = UISwitch()
            toggle.isOn = isAIFeedbackEnabled()
            toggle.addTarget(self, action: #selector(aiFeedbackSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }
        cell.accessoryView = nil

        // Show disclosure for actionable rows
        let section = Section(rawValue: indexPath.section)
        if section == .appearance || section == .actions || section == .dangerZone || section == .account || (section == .about && indexPath.row > 0) {
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

        case .feedback:
            break

        case .account:
            showEditField(for: indexPath.row)

        case .about:
            if indexPath.row == 1 {
                let vc = LegalViewController()
                vc.docTitle = "Privacy Policy"
                vc.contentText = """
                Privacy Policy for OpenTone
                
                Last Updated: March 2026
                
                Welcome to OpenTone! Your privacy is critically important to us.
                
                1. Information We Collect
                - Account Information: When you create an account, we collect your name, email address, age, and country.
                - Usage Data: We track your streaks, activity history, jam sessions, and roleplay progress to enhance your experience.
                - Voice & Audio Data: When using Jam Sessions or Roleplay Sessions, your voice is processed to provide AI-generated feedback and coaching. Audio is processed temporarily and not stored permanently unless explicitly saved by you.
                
                2. How We Use Your Data
                - To provide AI-enabled feedback on your language proficiency.
                - To maintain your streak and progression statistics.
                - To improve our core ML speech-coaching models.
                
                3. Data Sharing
                We do not sell your personal data. We use secure third-party services (like Supabase for database hosting and language models for AI analysis) strictly to operate the App.
                
                4. Account Deletion
                You can permanently delete your account and all associated data at any time via the Settings screen.
                
                Contact us at opentone.privacy@gmail.com for any questions.
                
                Or read our full Privacy Policy online at:
                https://www.opentone.in/privacy
                """
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                let vc = LegalViewController()
                vc.docTitle = "Terms of Service"
                vc.contentText = """
                Terms of Service for OpenTone
                
                Last Updated: March 2026
                
                1. Acceptance of Terms
                By using OpenTone, you agree to these Terms of Service. If you do not agree, please do not use the app.
                
                2. Description of Service
                OpenTone is an AI-powered communication and language coaching platform offering features such as Jam Sessions and Roleplay Scenarios.
                
                3. User Conduct
                You agree to use OpenTone constructively. Any abusive language, harassment, or inappropriate behavior during Roleplay or Call Sessions may result in account termination.
                
                4. AI Feedback
                OpenTone uses advanced AI models to provide speech feedback. While we strive for accuracy, the feedback is for educational purposes only and should not be considered professional or certified language evaluation.
                
                5. Intellectual Property
                All content, features, and functionality of OpenTone are owned by us and are protected by copyright laws.
                
                6. Termination
                We reserve the right to suspend or terminate your account without notice if you violate these terms.
                
                Contact us at opentone.support@gmail.com for help.
                
                Or visit our support page online at:
                https://www.opentone.in/support
                """
                navigationController?.pushViewController(vc, animated: true)
            }

        case .actions:
            confirmLogout()

        case .dangerZone:
            confirmDeleteAccount()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50 // HIG minimum 44pt touch target + padding
    }
}

// MARK: - LegalViewController

final class LegalViewController: UIViewController {

    let textContentView = UITextView()

    var docTitle: String = ""
    var contentText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = docTitle
        view.backgroundColor = AppColors.screenBackground
        navigationItem.largeTitleDisplayMode = .never

        textContentView.isEditable = false
        textContentView.isSelectable = true
        textContentView.dataDetectorTypes = .link
        textContentView.font = .systemFont(ofSize: 15, weight: .regular)
        textContentView.textColor = AppColors.textPrimary
        textContentView.backgroundColor = AppColors.screenBackground
        textContentView.text = contentText
        textContentView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        textContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textContentView)

        NSLayoutConstraint.activate([
            textContentView.topAnchor.constraint(equalTo: view.topAnchor),
            textContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
