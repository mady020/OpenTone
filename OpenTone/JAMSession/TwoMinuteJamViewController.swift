//
//  TwoMinuteJamViewController.swift
//  OpenTone
//
//  Created by Ardhanya Sharma on 17/12/25.
//
import UIKit

final class TwoMinuteJamViewController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet weak var unleashButton: UIButton!

    private weak var pendingTabController: UIViewController?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        tabBarController?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDarkModeStyles()
        setupProfileBarButton()
    }

    private func setupProfileBarButton() {
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(openProfile)
        )
        profileButton.tintColor = AppColors.primary
        navigationItem.rightBarButtonItem = profileButton
    }

    @objc private func openProfile() {
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        guard let profileNav = storyboard.instantiateInitialViewController() as? UINavigationController,
              let profileVC = profileNav.viewControllers.first else { return }
        navigationController?.pushViewController(profileVC, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyDarkModeStyles()
        }
    }

    private func applyDarkModeStyles() {
        // Main screen background
        view.backgroundColor = AppColors.screenBackground

        // Style the unleash button
        styleUnleashButton()

        // Style all subviews recursively
        styleSubviews(view)
    }

    private func styleUnleashButton() {
        unleashButton.tintColor = AppColors.textOnPrimary
        unleashButton.layer.shadowColor = AppColors.primary.cgColor
        unleashButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        unleashButton.layer.shadowRadius = 10
        unleashButton.layer.shadowOpacity = 0.3
        unleashButton.layer.masksToBounds = false
    }

    private func styleSubviews(_ parentView: UIView) {
        for subview in parentView.subviews {
            if let visualEffectView = subview as? UIVisualEffectView {
                styleVisualEffectView(visualEffectView)
            } else if let label = subview as? UILabel {
                // Labels with nil textColor in storyboard default to .label, but
                // ensure they use our dynamic color for consistency
                if label.textColor == .black || label.textColor == UIColor.label {
                    label.textColor = AppColors.textPrimary
                }
            }
            // Recurse into child views
            styleSubviews(subview)
        }
    }

    private func styleVisualEffectView(_ effectView: UIVisualEffectView) {
        let isDark = traitCollection.userInterfaceStyle == .dark

        // Update blur effect to match current mode
        effectView.effect = UIBlurEffect(
            style: isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        )

        // Update the content view and any nested visual effect views
        let lightPurpleBg = AppColors.primaryLight
        for sub in effectView.contentView.subviews {
            if let nested = sub as? UIVisualEffectView {
                nested.effect = UIBlurEffect(style: isDark ? .dark : .regular)
                nested.contentView.backgroundColor = isDark
                    ? UIColor.secondarySystemGroupedBackground
                    : lightPurpleBg
            }
        }

        // Style the effect view's own content background
        effectView.contentView.backgroundColor = isDark
            ? UIColor.secondarySystemGroupedBackground
            : lightPurpleBg

        // If it has rounded corners (the "How It Works" card), add card styling
        if effectView.layer.cornerRadius >= 20 {
            effectView.backgroundColor = isDark
                ? UIColor.secondarySystemGroupedBackground
                : lightPurpleBg
            effectView.layer.borderWidth = 1
            effectView.layer.borderColor = isDark
                ? UIColor.separator.cgColor
                : AppColors.primary.withAlphaComponent(0.15).cgColor
        }
    }

    // MARK: - Actions

    @IBAction func unleashTapped(_ sender: UIButton) {

        guard JamSessionDataModel.shared.hasActiveSession() else {
            startNewSession()
            return
        }

        showSessionAlert()
    }

    private func showSessionAlert() {

        let alert = UIAlertController(
            title: "Session Running",
            message: "Continue with current topic or start a new one?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            self.navigateToPrepare(resetTimer: false)
        })

        alert.addAction(UIAlertAction(title: "New Topic", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
            self.startNewSession()
        })

        present(alert, animated: true)
    }

    private func startNewSession() {
        JamSessionDataModel.shared.startNewSession()
        navigateToPrepare(resetTimer: true)
    }

    private func navigateToPrepare(resetTimer: Bool) {

        guard let prepareVC = storyboard?
            .instantiateViewController(withIdentifier: "PrepareJamViewController")
                as? PrepareJamViewController else { return }

        prepareVC.forceTimerReset = resetTimer
        navigationController?.pushViewController(prepareVC, animated: true)
    }

    // MARK: - Tab Bar Guard

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {

        guard JamSessionDataModel.shared.hasActiveSession() else {
            return true
        }

        pendingTabController = viewController
        showEndSessionAlert()
        return false
    }

    private func showEndSessionAlert() {

        let alert = UIAlertController(
            title: "Session Running",
            message: "Do you want to save this session for later or exit?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save & Exit", style: .default) { _ in
            JamSessionDataModel.shared.saveSessionForLater()
            self.switchToPendingTab()
        })

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
            self.switchToPendingTab()
        })

        present(alert, animated: true)
    }

    private func switchToPendingTab() {
        // Pop back to root in case we're deep in the nav stack
        navigationController?.popToRootViewController(animated: false)

        if let targetVC = pendingTabController {
            tabBarController?.selectedViewController = targetVC
            pendingTabController = nil
        }
    }
}
