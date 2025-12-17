//
//  TwoMinuteJamViewController.swift
//  OpenTone
//
//  Created by Ardhanya Sharma on 17/12/25.
//

import UIKit

final class TwoMinuteJamViewController: UIViewController {

    @IBOutlet weak var unleashButton: UIButton!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.isHidden = false
        configureNextButton()
    }

    private func configureNextButton() {
        if JamSessionDataModel.shared.getActiveSession() != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Next",
                style: .done,
                target: self,
                action: #selector(nextTapped)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func nextTapped() {
        JamSessionDataModel.shared.continueSession()

        guard let prepareVC = storyboard?
            .instantiateViewController(withIdentifier: "PrepareJamViewController")
                as? PrepareJamViewController else { return }

        navigationController?.pushViewController(prepareVC, animated: true)
    }

    @IBAction func unleashTapped(_ sender: UIButton) {

        if JamSessionDataModel.shared.getActiveSession() != nil {
            showReplaceSessionAlert()
        } else {
            startNewSession()
        }
    }

    private func startNewSession() {
        JamSessionDataModel.shared.startNewSession()

        guard let prepareVC = storyboard?
            .instantiateViewController(withIdentifier: "PrepareJamViewController")
                as? PrepareJamViewController else { return }

        navigationController?.pushViewController(prepareVC, animated: true)
    }

    private func showReplaceSessionAlert() {

        let alert = UIAlertController(
            title: "New Topic?",
            message: "Starting a new topic will end the current session.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Continue", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
            self.startNewSession()
        })

        present(alert, animated: true)
    }
}
