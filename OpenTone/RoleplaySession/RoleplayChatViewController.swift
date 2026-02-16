import UIKit
import AVFoundation

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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var replayButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    
    var scenario: RoleplayScenario!
    var session: RoleplaySession!
    var entryPoint: RoleplayEntryPoint = .roleplays
    
    private var messages: [ChatMessage] = []
    private var didLoadChat = false

    private var currentWrongStreak = 0
    private var totalWrongAttempts = 0

    private var isProcessingResponse = false
    private var isMuted = false

    // MARK: - TTS

    private let speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Gemini conversation history (for this roleplay)

    private var geminiHistory: [GeminiService.Message] = []
    private var geminiTurnCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard scenario != nil, session != nil else {
            fatalError("RoleplayChatVC: Scenario or Session not passed")
        }

        // Keep the data model in sync so save-for-later works
        RoleplaySessionDataModel.shared.activeScenario = scenario

        title = scenario.title
        speechSynthesizer.delegate = self
        setupUI()
        setupTableView()
        setupButtons()

        AudioManager.shared.onFinalTranscription = { [weak self] text in
            print("🎤 USER SAID:", text)
            self?.userResponded(text)
            self?.updateMicUI(isRecording: false)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = nil
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = AppColors.screenBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
    }
    
    private func setupButtons() {
        // Mic button
        UIHelper.styleCircularIconButton(micButton, symbol: "mic.fill")

        // Replay button — repurpose as mute toggle
        UIHelper.styleCircularIconButton(replayButton, symbol: "speaker.wave.2.fill")
        replayButton.removeTarget(nil, action: nil, for: .allEvents)
        replayButton.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)

        // Exit button
        UIHelper.styleCircularIconButton(exitButton, symbol: "xmark")
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: RoleplayChatViewController, _) in
            UIHelper.updateCircularIconButton(self.micButton)
            UIHelper.updateCircularIconButton(self.replayButton)
            UIHelper.updateCircularIconButton(self.exitButton)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didLoadChat {
            didLoadChat = true
            startGeminiRoleplay()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        speechSynthesizer.stopSpeaking(at: .immediate)

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
        }

        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Gemini-powered Roleplay

    private func buildRoleplaySystemPrompt() -> String {
        return """
        You are playing a character in a roleplay scenario for an English language learning app called OpenTone.

        SCENARIO: \(scenario.title)
        DESCRIPTION: \(scenario.description)

        RULES:
        1. Stay in character for this scenario at all times.
        2. Keep each message to 1-2 short sentences (this will be spoken via TTS).
        3. After each message, provide EXACTLY 3 suggested responses the learner could say, formatted as a JSON array on a new line starting with "SUGGESTIONS:".
        4. The suggestions should range from simple to more advanced English.
        5. Be encouraging and patient — the user is practicing English.
        6. Do NOT use markdown, emojis, or special formatting.
        7. If the user says something grammatically incorrect, gently rephrase it correctly in your response before continuing.
        8. Keep the conversation going naturally within the scenario context.

        FORMAT your response EXACTLY like this:
        [Your in-character message here]
        SUGGESTIONS:["suggestion 1","suggestion 2","suggestion 3"]

        Start the roleplay now with your opening line.
        """
    }

    private func startGeminiRoleplay() {
        geminiHistory.removeAll()
        geminiTurnCount = 0
        isProcessingResponse = true

        // Show a loading indicator
        messages.append(ChatMessage(sender: .app, text: "Starting roleplay…", suggestions: nil))
        reloadTableSafely()

        Task {
            do {
                let systemPrompt = buildRoleplaySystemPrompt()
                let reply = try await sendToGeminiForRoleplay(systemPrompt)
                await MainActor.run {
                    // Remove loading message
                    if messages.last?.text == "Starting roleplay…" {
                        messages.removeLast()
                    }
                    handleGeminiResponse(reply)
                    isProcessingResponse = false
                }
            } catch {
                await MainActor.run {
                    if messages.last?.text == "Starting roleplay…" {
                        messages.removeLast()
                    }
                    // Fallback to scripted mode
                    fallbackToScriptedMode()
                    isProcessingResponse = false
                }
            }
        }
    }

    private func sendToGeminiForRoleplay(_ text: String) async throws -> String {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiService.GeminiError.noAPIKey
        }

        geminiHistory.append(GeminiService.Message(role: .user, text: text))

        let models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"]
        let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

        var lastError: Error = GeminiService.GeminiError.emptyResponse

        for model in models {
            do {
                let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
                guard let url = URL(string: urlString) else { continue }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30

                var contents: [[String: Any]] = []
                for msg in geminiHistory {
                    contents.append([
                        "role": msg.role.rawValue,
                        "parts": [["text": msg.text]]
                    ])
                }

                let body: [String: Any] = [
                    "contents": contents,
                    "generationConfig": [
                        "temperature": 0.8,
                        "topP": 0.9,
                        "maxOutputTokens": 300
                    ]
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    if http.statusCode == 429 && (bodyStr.contains("limit: 0") || bodyStr.contains("RESOURCE_EXHAUSTED")) {
                        continue // try next model
                    }
                    throw GeminiService.GeminiError.httpError(http.statusCode, bodyStr)
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let first = candidates.first,
                      let content = first["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let textPart = parts.first,
                      let text = textPart["text"] as? String,
                      !text.isEmpty else {
                    throw GeminiService.GeminiError.emptyResponse
                }

                let reply = text.trimmingCharacters(in: .whitespacesAndNewlines)
                geminiHistory.append(GeminiService.Message(role: .model, text: reply))
                return reply

            } catch GeminiService.GeminiError.httpError(429, _) {
                lastError = GeminiService.GeminiError.rateLimited
                continue
            } catch {
                lastError = error
                // Remove user message if we fail
                if geminiHistory.last?.role == .user {
                    geminiHistory.removeLast()
                }
                throw error
            }
        }

        if geminiHistory.last?.role == .user {
            geminiHistory.removeLast()
        }
        throw lastError
    }

    private func handleGeminiResponse(_ response: String) {
        geminiTurnCount += 1
        let (messageText, suggestions) = parseGeminiResponse(response)

        messages.append(ChatMessage(sender: .app, text: messageText, suggestions: nil))

        if !suggestions.isEmpty {
            messages.append(ChatMessage(sender: .suggestions, text: "", suggestions: suggestions))
        }

        reloadTableSafely()
        speakText(messageText)
    }

    private func parseGeminiResponse(_ response: String) -> (String, [String]) {
        let lines = response.components(separatedBy: "\n")
        var messageLines: [String] = []
        var suggestions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("SUGGESTIONS:") {
                let jsonPart = String(trimmed.dropFirst("SUGGESTIONS:".count))
                    .trimmingCharacters(in: .whitespaces)
                if let data = jsonPart.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
                    suggestions = parsed
                }
            } else if !trimmed.isEmpty {
                messageLines.append(trimmed)
            }
        }

        let messageText = messageLines.joined(separator: " ")
        return (messageText.isEmpty ? response : messageText, suggestions)
    }

    // MARK: - Fallback to scripted mode

    private var isScriptedMode = false

    private func fallbackToScriptedMode() {
        isScriptedMode = true
        print("⚠️ Falling back to scripted roleplay mode")
        loadCurrentStep()
    }

    private func loadCurrentStep() {
        let index = session.currentLineIndex
        guard index < scenario.script.count else {
            presentScoreScreen()
            return
        }

        let message = scenario.script[index]

        messages.append(
            ChatMessage(sender: .app, text: message.text, suggestions: nil)
        )

        if let options = message.replyOptions {
            messages.append(
                ChatMessage(sender: .suggestions, text: "", suggestions: options)
            )
        }

        reloadTableSafely()
        speakText(message.text)
    }

    // MARK: - TTS

    private func speakText(_ text: String) {
        guard !isMuted else { return }

        // Stop any ongoing recording while TTS plays
        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
            updateMicUI(isRecording: false)
        }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Mute

    @objc private func muteTapped() {
        isMuted.toggle()
        AudioManager.shared.setMuted(isMuted)

        replayButton.setImage(
            UIImage(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"),
            for: .normal
        )

        if isMuted {
            speechSynthesizer.stopSpeaking(at: .immediate)
            if AudioManager.shared.isRecording {
                AudioManager.shared.stopRecording()
                updateMicUI(isRecording: false)
            }
        }
    }

    // MARK: - Mic UI
    
    private func updateMicUI(isRecording: Bool) {
        micButton.backgroundColor = isRecording
            ? UIColor.systemRed
            : AppColors.cardBackground
    }

    
    @IBAction func micTapped(_ sender: UIButton) {
        guard !isMuted else { return }

        // Stop TTS if playing so user can speak
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
            updateMicUI(isRecording: false)
        } else {
            AudioManager.shared.startRecording()
            updateMicUI(isRecording: true)
        }
    }



    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: "[^a-z ]",
                with: "",
                options: .regularExpression
            )
    }



    
    private func userResponded(_ text: String) {

        guard !isProcessingResponse else { return }
        guard !isMuted else { return }
        isProcessingResponse = true

        // Remove suggestions
        if messages.last?.sender == .suggestions {
            messages.removeLast()
        }

        // Append user message
        messages.append(
            ChatMessage(sender: .user, text: text, suggestions: nil)
        )

        reloadTableSafely()

        if isScriptedMode {
            handleScriptedResponse(text)
        } else {
            handleGeminiUserResponse(text)
        }
    }

    // MARK: - Gemini response flow

    private func handleGeminiUserResponse(_ text: String) {
        // Show thinking indicator
        messages.append(ChatMessage(sender: .app, text: "…", suggestions: nil))
        reloadTableSafely()

        Task {
            do {
                let reply = try await sendToGeminiForRoleplay(text)
                await MainActor.run {
                    // Remove thinking indicator
                    if messages.last?.text == "…" {
                        messages.removeLast()
                    }
                    session.currentLineIndex += 1
                    handleGeminiResponse(reply)
                    isProcessingResponse = false

                    // Check if we should end after enough turns
                    if geminiTurnCount >= scenario.script.count {
                        endGeminiRoleplay()
                    }
                }
            } catch {
                await MainActor.run {
                    if messages.last?.text == "…" {
                        messages.removeLast()
                    }
                    messages.append(ChatMessage(
                        sender: .app,
                        text: "Sorry, something went wrong. Please try again.",
                        suggestions: nil
                    ))
                    reloadTableSafely()
                    isProcessingResponse = false
                }
            }
        }
    }

    private func endGeminiRoleplay() {
        session.status = .completed
        session.endedAt = Date()

        RoleplaySessionDataModel.shared.updateSession(session, scenario: scenario)
        StreakDataModel.shared.logSession(
            title: "Roleplay Session",
            subtitle: "You completed a roleplay",
            topic: scenario.title,
            durationMinutes: scenario.estimatedTimeMinutes,
            xp: 30,
            iconName: "person.2.fill"
        )
        SessionProgressManager.shared.markCompleted(.roleplay, topic: scenario.title)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.presentScoreScreen()
        }
    }

    // MARK: - Scripted response flow

    private func handleScriptedResponse(_ text: String) {
        let index = session.currentLineIndex
        let expected = scenario.script[index].replyOptions ?? []
        let normalizedInput = normalize(text)

        let isCorrect = expected.contains { option in
            let normalizedOption = normalize(option)
            let inputWords = Set(normalizedInput.split(separator: " "))
            let optionWords = Set(normalizedOption.split(separator: " "))
            return inputWords.intersection(optionWords).count >= 2
        }

        if isCorrect {
            currentWrongStreak = 0
            advanceSession()
        } else {
            handleWrongAttempt(expected: expected)
            isProcessingResponse = false
        }
    }

    private func advanceSession() {
        session.currentLineIndex += 1

        if session.currentLineIndex < scenario.script.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadCurrentStep()
                self.isProcessingResponse = false
            }
        } else {
            session.status = .completed
            session.endedAt = Date()

            RoleplaySessionDataModel.shared.updateSession(session, scenario: scenario)
            StreakDataModel.shared.logSession(
                title: "Roleplay Session",
                subtitle: "You completed a roleplay",
                topic: scenario.title,
                durationMinutes: scenario.estimatedTimeMinutes,
                xp: 30,
                iconName: "person.2.fill"
            )
            SessionProgressManager.shared.markCompleted(.roleplay, topic: scenario.title)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.presentScoreScreen()
            }
        }
    }


    private func handleWrongAttempt(expected: [String]) {
        currentWrongStreak += 1
        totalWrongAttempts += 1

        messages.append(
            ChatMessage(sender: .app, text: "Not quite 🤏\nTry one of the options below!", suggestions: nil)
        )
        messages.append(
            ChatMessage(sender: .suggestions, text: "", suggestions: expected)
        )

        reloadTableSafely()
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
        showExitAlert()
    }

    @objc private func exitButtonTapped() {
        showExitAlert()
    }

    private func showExitAlert() {
        speechSynthesizer.stopSpeaking(at: .immediate)

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
            updateMicUI(isRecording: false)
        }

        let alert = UIAlertController(
            title: "Leave Roleplay?",
            message: "Save your progress and continue later, or exit without saving.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save & Exit", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.session.status = .paused
            RoleplaySessionDataModel.shared.updateSession(self.session, scenario: self.scenario)
            RoleplaySessionDataModel.shared.saveSessionForLater()
            self.popBackToOrigin()
        })

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] _ in
            RoleplaySessionDataModel.shared.cancelSession()
            self?.popBackToOrigin()
        })

        present(alert, animated: true)
    }

    private func popBackToOrigin() {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }


    
    @IBAction func replayTapped(_ sender: UIButton) {
        // This is now handled by muteTapped via the repurposed button
    }

    
    private func replayRoleplayFromStart() {
        speechSynthesizer.stopSpeaking(at: .immediate)

        session.currentLineIndex = 0
        session.status = .notStarted
        session.endedAt = nil

        messages.removeAll()
        currentWrongStreak = 0
        totalWrongAttempts = 0
        geminiHistory.removeAll()
        geminiTurnCount = 0
        isScriptedMode = false

        tableView.reloadData()

        startGeminiRoleplay()
    }

    private func presentScoreScreen() {
        speechSynthesizer.stopSpeaking(at: .immediate)

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)

        guard let scoreVC = storyboard.instantiateViewController(
            withIdentifier: "ScoreScreenVC"
        ) as? ScoreViewController else { return }

        scoreVC.score = calculateScore()
        scoreVC.pointsEarned = 5

        present(scoreVC, animated: true)
    }

}

// MARK: - AVSpeechSynthesizerDelegate

extension RoleplayChatViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Reset audio session for recording after TTS finishes
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try? session.setActive(true)
    }
}

// MARK: - UITableView

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
