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
    private var isSpeaking = false

    private var audioPlayer: AVAudioPlayer?

    // MARK: - Scripted roleplay (primary mode)
    // Ollama-powered roleplay remains available as a fallback path.

    private struct LLMMessage {
        enum Role: String { case user, model }
        let role: Role
        let text: String
    }

    private var llmHistory: [LLMMessage] = []
    private var geminiTurnCount = 0  // reused for LLM turn tracking

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard scenario != nil, session != nil else {
            fatalError("RoleplayChatVC: Scenario or Session not passed")
        }

        // Keep the data model in sync so save-for-later works
        RoleplaySessionDataModel.shared.activeScenario = scenario

        title = scenario.title
        setupUI()
        setupTableView()
        setupButtons()

        AudioManager.shared.onFinalTranscription = { [weak self] text in
            print("🎤 USER SAID:", text)
            self?.userResponded(text)
        }

        AudioManager.shared.onRecordingStateChanged = { [weak self] isRecording in
            DispatchQueue.main.async {
                self?.updateMicUI(isRecording: isRecording)
            }
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !didLoadChat {
            didLoadChat = true
            // Scripted mode is the default — deterministic and instant.
            isScriptedMode = true
            loadCurrentStep()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        audioPlayer?.stop()

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
        llmHistory.removeAll()
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
        // Build history context
        let historySnippet = llmHistory.suffix(8).map {
            "\($0.role == .user ? "USER" : "ASSISTANT"): \($0.text)"
        }.joined(separator: "\n")

        llmHistory.append(LLMMessage(role: .user, text: text))

        let baseURL = "http://44.221.98.186:11434"
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw URLError(.badURL)
        }

        let systemPrompt = buildRoleplaySystemPrompt()
        let fullPrompt = "\(systemPrompt)\n\nConversation so far:\n\(historySnippet)\nUSER: \(text)\nASSISTANT:"

        let body: [String: Any] = [
            "model": "mistral",
            "prompt": fullPrompt,
            "stream": false,
            "options": ["temperature": 0.8, "num_predict": 300]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["response"] as? String, !reply.isEmpty else {
            throw URLError(.badServerResponse)
        }

        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        llmHistory.append(LLMMessage(role: .model, text: trimmed))
        return trimmed
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
        var messageText = response
        var suggestions: [String] = []

        if let range = response.range(of: "SUGGESTIONS:") {
            messageText = String(response[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let jsonString = String(response[range.upperBound...])
                .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let data = jsonString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
                suggestions = parsed
            }
        }

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
        guard !isSpeaking else { return }  // prevent overlapping audio
        isSpeaking = true

        // Stop any ongoing recording WITHOUT auto-transcribe to prevent
        // the callback → userResponded → advanceSession → speakText loop
        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording(autoTranscribe: false)
        }

        Task {
            do {
                let audioData = try await BackendSpeechService.shared.tts(text: text)
                
                await MainActor.run {
                    guard !self.isMuted else {
                        self.isSpeaking = false
                        return
                    }
                    
                    let session = AVAudioSession.sharedInstance()
                    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try? session.setActive(true)
                    
                    do {
                        self.audioPlayer?.stop()  // stop any leftover playback
                        self.audioPlayer = try AVAudioPlayer(data: audioData)
                        self.audioPlayer?.delegate = self
                        self.audioPlayer?.prepareToPlay()
                        self.audioPlayer?.play()
                    } catch {
                        print("Roleplay Audio Player Error: \(error)")
                        self.isSpeaking = false
                    }
                }
            } catch {
                print("Roleplay TTS Error: \(error)")
                await MainActor.run { self.isSpeaking = false }
            }
        }
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
            audioPlayer?.stop()
            if AudioManager.shared.isRecording {
                AudioManager.shared.stopRecording()
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

        // Stop TTS if playing so user can speak
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
        } else {
            AudioManager.shared.startRecording()
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
        
        // Prevent empty messages from blowing up the UI and crashing Gemini
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        guard !isProcessingResponse else { return }
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
        
        // Calculate actual duration in minutes
        let seconds = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0
        let actualMinutes = max(1, Int(seconds) / 60)

        SessionProgressManager.shared.markCompleted(.roleplay, topic: scenario.title, actualDurationMinutes: actualMinutes)

        // Build user transcript from conversation history
        let userTranscript = llmHistory
            .filter { $0.role == .user }
            .map { $0.text }
            .joined(separator: " ")

        fetchEndSessionFeedback(
            userTranscript: userTranscript,
            durationSeconds: seconds,
            delayBeforePresent: 1.0
        )
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
            
            // Calculate actual duration in minutes
            let seconds = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0
            let actualMinutes = max(1, Int(seconds) / 60)

            SessionProgressManager.shared.markCompleted(.roleplay, topic: scenario.title, actualDurationMinutes: actualMinutes)

            // Build user transcript from the scripted user messages
            let userTranscript = messages
                .filter { $0.sender == .user }
                .map { $0.text }
                .joined(separator: " ")

            fetchEndSessionFeedback(
                userTranscript: userTranscript,
                durationSeconds: seconds,
                delayBeforePresent: 0.8
            )
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
        audioPlayer?.stop()

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording()
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
        audioPlayer?.stop()

        session.currentLineIndex = 0
        session.status = .notStarted
        session.endedAt = nil

        messages.removeAll()
        currentWrongStreak = 0
        totalWrongAttempts = 0
        isScriptedMode = true

        tableView.reloadData()

        loadCurrentStep()
    }

    // MARK: - End-session feedback

    /// Fetch comprehensive feedback from the backend and present feedback screen.
    /// Falls back to the basic ScoreViewController if the backend call fails.
    private func fetchEndSessionFeedback(
        userTranscript: String,
        durationSeconds: Double,
        delayBeforePresent: Double
    ) {
        let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "demo"
        let sessionId = session.id.uuidString
        let lastAudioData: Data? = {
            guard let url = AudioManager.shared.lastRecordingURL else { return nil }
            return try? Data(contentsOf: url)
        }()

        Task {
            do {
                let response = try await BackendSpeechService.shared.endSession(
                    lastAudioData: lastAudioData,
                    fullTranscript: userTranscript,
                    totalDurationS: durationSeconds,
                    userId: userId,
                    sessionId: sessionId,
                    turnSummaries: [],
                    mode: "roleplay"
                )

                await MainActor.run {
                    // Present feedback VC instead of simple score screen
                    let feedbackVC = FeedbackCollectionViewController()
                    feedbackVC.transcript = userTranscript
                    feedbackVC.topic = scenario.title
                    feedbackVC.speakingDuration = durationSeconds
                    feedbackVC.sessionId = sessionId
                    feedbackVC.userId = userId
                    feedbackVC.preloadedResponse = response

                    let nav = UINavigationController(rootViewController: feedbackVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            } catch {
                print("❌ Roleplay end-session feedback failed: \(error.localizedDescription)")
                await MainActor.run {
                    // Fall back to basic score screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforePresent) {
                        self.presentScoreScreen()
                    }
                }
            }
        }
    }

    private func presentScoreScreen() {
        audioPlayer?.stop()

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)

        guard let scoreVC = storyboard.instantiateViewController(
            withIdentifier: "ScoreScreenVC"
        ) as? ScoreViewController else { return }

        scoreVC.score = calculateScore()
        scoreVC.pointsEarned = 5
        scoreVC.modalPresentationStyle = .fullScreen

        scoreVC.onDismiss = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
            self?.navigationController?.popToRootViewController(animated: true)
        }

        present(scoreVC, animated: true)
    }

}

// MARK: - AVAudioPlayerDelegate

extension RoleplayChatViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        // Keep playAndRecord so both mic recording and future TTS work without session conflicts
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
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
