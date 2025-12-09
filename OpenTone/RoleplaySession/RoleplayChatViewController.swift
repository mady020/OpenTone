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
    private var initialLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        // For automatic dynamic height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    // 🔥 FIX: Only load script after view is fully on screen
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        if !initialLoaded {
//            initialLoaded = true
//            loadStep(0)
//        }
//    }
    
    private var didLoadChat = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didLoadChat {
            didLoadChat = true
            loadStep(0)   // 👍 tableView is guaranteed to exist here
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
}

// MARK: - Suggestions Tap
extension RoleplayChatViewController: SuggestionCellDelegate {
    func didTapSuggestion(_ suggestion: String) {
        userResponded(suggestion)
    }
}
