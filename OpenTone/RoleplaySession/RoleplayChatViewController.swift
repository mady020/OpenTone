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

    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var micButton: UIButton!

    var messages: [ChatMessage] = []

  
    


    var step = 0
    private var initialLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        // For automatic dynamic height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        
        navigationItem.hidesBackButton = true

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

        guard let scenario = currentScenario else {
            return
        }
        let appMessage = scenario.script[i].text
        let suggestedRoleplayMessages = scenario.script[i].suggestedMessages
        var suggestedMessages : [String] = []
        if let suggestedRoleplayMessages{
            for message in suggestedRoleplayMessages {
                suggestedMessages.append(message)
            }
        }
       
        
        // 1️⃣ App message
        messages.append(
            ChatMessage(sender: .app,
                        text: appMessage,
                        suggestions: nil)
        )

        // 2️⃣ Suggestions bubble
        messages.append(
            ChatMessage(sender: .suggestions,
                        text: "",
                        suggestions:  suggestedMessages)
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

    var wrongAttempts = 0

    func userResponded(_ text: String) {
       
        guard let scenario = currentScenario else {
            return
        }
        let suggestedRoleplayMessages = scenario.script[step].suggestedMessages
        var suggestedMessages : [String]
        if let suggestedRoleplayMessages{
            for message in suggestedRoleplayMessages {
                suggestedMessages.append(message)
            }
        }
        
        
        let expectedSuggestions = suggestedMessages.map { $0.lowercased() }
        let spoken = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if expectedSuggestions.contains(spoken) {
            // Reset wrong attempts
            wrongAttempts = 0

            // VALID response 👍
            if messages.last?.sender == .suggestions {
                messages.removeLast()
            }

            messages.append(ChatMessage(sender: .user, text: text, suggestions: nil))
            reloadTableSafely()

            // Move next
            // NEXT STEP HANDLING
            if step + 1 < scenario.script.count {
                // Continue script
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.loadStep(self.step + 1)
                }
            } else {
                // Script is finished 👍
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.presentScoreScreen()
                }
            }


        } else {
            wrongAttempts += 1

            if wrongAttempts < 3 {
                // Friendly reminders
                messages.append(
                    ChatMessage(
                        sender: .app,
                        text: "Not quite 🤏\nTry saying one of the options below!",
                        suggestions: nil
                    )
                )

            } else {
                // After 3 attempts → show correct answer & move on
                wrongAttempts = 0

                let correct = suggestedMessages.first ?? "Default correct answer"
                messages.append(
                    ChatMessage(
                        sender: .app,
                        text: "Correct phrasing: \"\(correct)\" 👍",
                        suggestions: nil
                    )
                )

                // Remove old suggestions & progress
                if messages.last?.sender == .suggestions {
                    messages.removeLast()
                }

                if step + 1 < scenario.script.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        self.loadStep(self.step + 1)
                    }
                }
            }

            reloadTableSafely()
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
        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
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


