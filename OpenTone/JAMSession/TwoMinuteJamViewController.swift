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
        view.backgroundColor = AppColors.screenBackground
        styleUnleashButton()
        styleSubviews(view)
    }

    private func styleUnleashButton() {
        UIHelper.styleLargeCTAButton(unleashButton, icon: "sparkles")
        unleashButton.setTitle("  Unleash a Topic", for: .normal)
    }

    private func styleSubviews(_ parentView: UIView) {
        for subview in parentView.subviews {
            if let visualEffectView = subview as? UIVisualEffectView {
                styleVisualEffectView(visualEffectView)
            } else if let label = subview as? UILabel {
                if label.textColor == .black || label.textColor == UIColor.label {
                    label.textColor = AppColors.textPrimary
                }
            }
            styleSubviews(subview)
        }
    }

    private func styleVisualEffectView(_ effectView: UIVisualEffectView) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        effectView.effect = UIBlurEffect(
            style: isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        )
        let lightPurpleBg = AppColors.primaryLight
        for sub in effectView.contentView.subviews {
            if let nested = sub as? UIVisualEffectView {
                nested.effect = UIBlurEffect(style: isDark ? .dark : .regular)
                nested.contentView.backgroundColor = isDark
                    ? UIColor.secondarySystemGroupedBackground
                    : lightPurpleBg
            }
        }

        effectView.contentView.backgroundColor = isDark
            ? UIColor.secondarySystemGroupedBackground
            : lightPurpleBg
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
        let hud = UIActivityIndicatorView(style: .large)
        hud.color = AppColors.primary
        hud.center = view.center
        hud.startAnimating()
        view.addSubview(hud)
        view.isUserInteractionEnabled = false

        JamSessionDataModel.shared.startNewSessionWithAI { [weak self] _ in
            guard let self = self else { return }
            hud.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
            self.navigateToPrepare(resetTimer: true)
        }
    }

    private func navigateToPrepare(resetTimer: Bool) {

        guard let prepareVC = storyboard?
            .instantiateViewController(withIdentifier: "PrepareJamViewController")
                as? PrepareJamViewController else { return }

        prepareVC.forceTimerReset = resetTimer
        navigationController?.pushViewController(prepareVC, animated: true)
    }


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
        navigationController?.popToRootViewController(animated: false)

        if let targetVC = pendingTabController {
            tabBarController?.selectedViewController = targetVC
            pendingTabController = nil
        }
    }
}
