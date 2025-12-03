//
//  RoleplayChatViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 02/12/25.
//

import UIKit

enum ChatSender {
    case app
    case user
    case suggestions
}

struct ChatMessage {
    let sender: ChatSender
    let text: String
    let suggestions: [String]?
}

class RoleplayChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var micButton: UIButton!

    var messages: [ChatMessage] = []

    // Simple script
    let script = [
        ("Where can I find the milk?",
         ["How much does this cost?", "I am looking for milk", "Where is checkout?"]),
        
        ("The milk is in the dairy section next to eggs.",
         ["Show me directions", "Got it!", "Can I pay by card?"]),
    ]

    var step = 0
    private var initialLoaded = false   // 👈 prevents double execution

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        // For automatic dynamic height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        (tabBarController as? MainTabBarController)?.isRoleplayInProgress = true
    }
    
    private var didLoadChat = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didLoadChat {
            didLoadChat = true
            loadStep(0)
        }
    }


    func loadStep(_ i: Int) {
        step = i

        // 1️⃣ App message
        messages.append(
            ChatMessage(sender: .app,
                        text: script[i].0,
                        suggestions: nil)
        )

        // 2️⃣ Suggestions bubble
        messages.append(
            ChatMessage(sender: .suggestions,
                        text: "",
                        suggestions: script[i].1)
        )

        reloadTableSafely()
    }

     //MARK: - Safe Reload + Scroll
    func reloadTableSafely() {
        tableView.reloadData()
        tableView.layoutIfNeeded()

        DispatchQueue.main.async {
            self.scrollToBottom()
        }
    }


    func scrollToBottom() {
        guard messages.count > 0 else { return }
        guard tableView != nil else { return }

        tableView.layoutIfNeeded()

        let last = messages.count - 1
        let index = IndexPath(row: last, section: 0)

        DispatchQueue.main.async {
            if last < self.tableView.numberOfRows(inSection: 0) {
                self.tableView.scrollToRow(at: index, at: .bottom, animated: true)
            }
        }
    }


    
    // MARK: - Mic Button
    @IBAction func micTapped(_ sender: UIButton) {
        simulateSpeechInput()
    }

    func simulateSpeechInput() {
        let alert = UIAlertController(title: "Mic Input",
                                      message: "Type what user said",
                                      preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.userResponded(text)
            }
        }))
        present(alert, animated: true)
    }

    func userResponded(_ text: String) {

        // Remove suggestions row BEFORE adding user message
        if messages.last?.sender == .suggestions {
            messages.removeLast()
        }

        // User bubble
        messages.append(
            ChatMessage(sender: .user,
                        text: text,
                        suggestions: nil)
        )

        reloadTableSafely()

        // Load next script line
        if step + 1 < script.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.loadStep(self.step + 1)
            }
        }
    }
}

// MARK: - UITableView
extension RoleplayChatViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let msg = messages[indexPath.row]

        switch msg.sender {

        case .app:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "AppMessageCell",
                for: indexPath
            ) as! AppMessageCell
            cell.messageLabel.text = msg.text
            return cell

        case .user:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "UserMessageCell",
                for: indexPath
            ) as! UserMessageCell
            cell.messageLabel.text = msg.text
            return cell

        case .suggestions:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "SuggestionCell",
                for: indexPath
            ) as! SuggestionCell
            cell.delegate = self
            cell.configure(msg.suggestions ?? [])
            return cell
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.delegate = self
    }

    func showRoleplayExitAlert(for viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Exit Roleplay?",
            message: "Your progress will be lost if you leave this screen.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Stay", style: .cancel))

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
            
            self.navigationController?.popViewController(animated: true)
            self.tabBarController?.selectedViewController = viewController
        }))

        present(alert, animated: true)
    }
    
    
    
    @IBAction func endButtonTapped(_ sender: UIBarButtonItem) {
        triggerScoreScreenFlow()
    }


    func triggerScoreScreenFlow() {
        // If alert is currently shown → dismiss then show Score
        if let alert = self.presentedViewController as? UIAlertController {
            alert.dismiss(animated: true) {
                self.presentScoreScreen()
            }
        } else {
            // Alert not showing → directly show Score
            self.presentScoreScreen()
        }
    }

    private func presentScoreScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let scoreVC = storyboard.instantiateViewController(withIdentifier: "ScoreScreenVC") as? ScoreViewController else { return }
        
        scoreVC.modalPresentationStyle = .fullScreen
        scoreVC.modalTransitionStyle = .crossDissolve
        self.present(scoreVC, animated: true)
    }


 


}


extension RoleplayChatViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {

        // If tapping the current tab, allow
        if viewController == tabBarController.selectedViewController {
            return true
        }

        // Show confirmation alert instead of switching tab
        showRoleplayExitAlert(for: viewController)
        return false
    }
}


// MARK: - Suggestions Tap
extension RoleplayChatViewController: SuggestionCellDelegate {
    func didTapSuggestion(_ suggestion: String) {
        userResponded(suggestion)
    }
}


