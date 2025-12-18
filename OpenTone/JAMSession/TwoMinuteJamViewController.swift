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
//        configureNavigationBar()
    }
    override func viewDidLoad() {
    }

//    private func configureNavigationBar() {
//
//        guard JamSessionDataModel.shared.hasActiveSession() else {
//            navigationItem.rightBarButtonItem = nil
//            return
//        }
//
//        let backButton = UIBarButtonItem(
//            title: "Back",
//            style: .plain,
//            target: self,
//            action: #selector(backTapped)
//        )
//
//        backButton.tintColor = UIColor(
//            red: 0.42, green: 0.05, blue: 0.68, alpha: 1.0
//        )
//
//        navigationItem.rightBarButtonItem = backButton
//    }

//    @objc private func backTapped() {
//        JamSessionDataModel.shared.continueSession()
//        navigateToPrepare(resetTimer: true)
//    }

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
            JamSessionDataModel.shared.continueSession()
            self.navigateToPrepare(resetTimer: true)
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
            message: "A session is going on. Do you want to end the session without completing?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "No", style: .cancel))

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()

            if let targetVC = self.pendingTabController {
                self.tabBarController?.selectedViewController = targetVC
                self.pendingTabController = nil
            }
        })

        present(alert, animated: true)
    }
}
