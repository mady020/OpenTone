import UIKit

enum ChatSender {
    case app
    case user
    case suggestions
}

enum RoleplayEntryPoint {
    case dashboard
    case roleplays
}


struct ChatMessage {
    let sender: ChatSender
    let text: String
    let suggestions: [String]?
}

extension RoleplayChatViewController: SuggestionCellDelegate {

    func didTapSuggestion(_ suggestion: String) {
        userResponded(suggestion)
    }
}




class RoleplayChatViewController: UIViewController {

    // MARK: - Passed Data (FROM prepare segue)
    var scenario: RoleplayScenario!
    var session: RoleplaySession!

    private var currentWrongStreak = 0
    private var totalWrongAttempts = 0

    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var micButton: UIButton!

    @IBOutlet var replayButton: UIButton!
    // MARK: - UI State
    private var messages: [ChatMessage] = []
    private var didLoadChat = false
     

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard scenario != nil, session != nil else {
            fatalError("RoleplayChatVC: Scenario or Session not passed")
        }

        title = scenario.title

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none

        navigationItem.hidesBackButton = true
        
        micButton.layer.cornerRadius = 28
        micButton.backgroundColor = AppColors.cardBackground
        micButton.layer.borderColor = AppColors.cardBorder.cgColor
        micButton.layer.borderWidth = 1
        
        replayButton.layer.cornerRadius = 28
        replayButton.backgroundColor = AppColors.cardBackground
        replayButton.layer.borderColor = AppColors.cardBorder.cgColor
        replayButton.layer.borderWidth = 1
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didLoadChat {
            didLoadChat = true
            loadCurrentStep()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    private func loadCurrentStep() {

        let index = session.currentLineIndex
        guard index < scenario.script.count else {
            presentScoreScreen()
            return
        }

        let message = scenario.script[index]

        messages.append(
            ChatMessage(
                sender: .app,
                text: message.text,
                suggestions: nil
            )
        )

        if let options = message.replyOptions {
            messages.append(
                ChatMessage(
                    sender: .suggestions,
                    text: "",
                    suggestions: options
                )
            )
        }

        reloadTableSafely()
    }

    @IBAction func micTapped(_ sender: UIButton) {
        simulateSpeechInput()
    }

    private func simulateSpeechInput() {
        let alert = UIAlertController(
            title: "Mic Input",
            message: "Type what user said",
            preferredStyle: .alert
        )
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.userResponded(text)
            }
        })
        present(alert, animated: true)
    }

    private func userResponded(_ text: String) {

        let index = session.currentLineIndex
        let expected = scenario.script[index].replyOptions ?? []
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if expected.map({ $0.lowercased() }).contains(normalized) {

            currentWrongStreak = 0

            if messages.last?.sender == .suggestions {
                messages.removeLast()
            }

            messages.append(
                ChatMessage(
                    sender: .user,
                    text: text,
                    suggestions: nil
                )
            )

            advanceSession()

        } else {
            handleWrongAttempt(expected: expected)
        }

        reloadTableSafely()
    }

    private func advanceSession() {

        session.currentLineIndex += 1

        if session.currentLineIndex < scenario.script.count {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadCurrentStep()
            }

        } else {
            session.status = .completed
            session.endedAt = Date()

            RoleplaySessionDataModel.shared.updateSession(
                session,
                scenario: scenario
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.presentScoreScreen()
            }
        }
    }


    private func handleWrongAttempt(expected: [String]) {

        currentWrongStreak += 1
        totalWrongAttempts += 1

        if currentWrongStreak < 3 {

            messages.append(
                ChatMessage(
                    sender: .app,
                    text: "Not quite 🤏\nTry one of the options below!",
                    suggestions: nil
                )
            )

        } else {

            currentWrongStreak = 0

            let correct = expected.first ?? ""
            messages.append(
                ChatMessage(
                    sender: .app,
                    text: "Correct phrasing:\n\"\(correct)\" 👍",
                    suggestions: nil
                )
            )

            if messages.last?.sender == .suggestions {
                messages.removeLast()
            }

            advanceSession()
        }
    }


    private func reloadTableSafely() {
        tableView.reloadData()
        tableView.layoutIfNeeded()
        scrollToBottom()
    }

    func scrollToBottom() {
        DispatchQueue.main.async {
            let rows = self.tableView.numberOfRows(inSection: 0)
            guard rows > 0 else { return }

            let lastIndex = IndexPath(row: rows - 1, section: 0)
            self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
        }
    }


    @IBAction func endButtonTapped(_ sender: UIBarButtonItem) {
        
        RoleplaySessionDataModel.shared.cancelSession()

    }


    
    @IBAction func replayTapped(_ sender: UIButton) {
        replayRoleplayFromStart()
    }

    
    private func replayRoleplayFromStart() {

        session.currentLineIndex = 0
        session.status = .notStarted
        session.endedAt = nil

        messages.removeAll()
        currentWrongStreak = 0
        totalWrongAttempts = 0

        tableView.reloadData()

        loadCurrentStep()
    }
   





    
    private func presentScoreScreen() {

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)

        guard let scoreVC = storyboard.instantiateViewController(
            withIdentifier: "ScoreScreenVC"
        ) as? ScoreViewController else { return }

        scoreVC.score = calculateScore()
        scoreVC.pointsEarned = 5


        present(scoreVC, animated: true)
    }

}

extension RoleplayChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    private func calculateScore() -> Int {
        let penalty = totalWrongAttempts * 5
        return max(100 - penalty, 60)
    }

    
    
   

    
   

}
