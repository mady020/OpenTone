import UIKit
import AVFoundation

private final class RoleplayDisplayLinkProxy {
    weak var target: RoleplayChatViewController?
    init(target: RoleplayChatViewController) { self.target = target }
    @objc func step(_ link: CADisplayLink) { target?.updateAnimation() }
}

private final class ProgrammaticChatBubbleCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds = true
        contentView.addSubview(bubbleView)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        bubbleView.addSubview(messageLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),
        ])
    }

    func configure(text: String, isUser: Bool) {
        messageLabel.text = text
        if isUser {
            messageLabel.textColor = AppColors.textOnPrimary
            bubbleView.backgroundColor = AppColors.primary
            bubbleView.layer.borderWidth = 0
            bubbleView.layer.borderColor = UIColor.clear.cgColor
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        } else {
            messageLabel.textColor = AppColors.textPrimary
            bubbleView.backgroundColor = AppColors.cardBackground
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = AppColors.cardBorder.cgColor
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        }
    }
}

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
    private var roleplayFeedbackObserver: NSObjectProtocol?

    private enum State {
        case idle
        case listening
        case processing
        case speaking
    }

    private var currentState: State = .idle {
        didSet { updateStatusLabel() }
    }

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var displayLink: CADisplayLink?
    private var displayLinkProxy: RoleplayDisplayLinkProxy?
    private let waveLayers: [CAShapeLayer] = (0..<5).map { _ in CAShapeLayer() }
    private var smoothedLevel: CGFloat = 0.1
    private let smoothingFactor: CGFloat = 0.15

    // MARK: - Scripted roleplay (primary mode)
    // Backend chat roleplay remains available as a fallback path.

    private struct LLMMessage {
        enum Role: String { case user, assistant }
        let role: Role
        let text: String
    }

    private var llmHistory: [LLMMessage] = []
    private var roleplayTurnCount = 0  // reused for LLM turn tracking
    private var pendingUserCorrection: UtteranceCorrection?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard scenario != nil, session != nil else {
            fatalError("RoleplayChatVC: Scenario or Session not passed")
        }

        // Keep the data model in sync so save-for-later works
        RoleplaySessionDataModel.shared.activeScenario = scenario

        buildProgrammaticLayout()

        title = scenario.title
        setupUI()
        setupTableView()
        setupButtons()
        setupWave()
        startDisplayLink()

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
        ])
        tableView.contentInset.top = 8
        currentState = .idle

        AudioManager.shared.onFinalTranscription = { [weak self] text in
            self?.handleUserTranscription(text)
        }

        AudioManager.shared.onAudioBuffer = { [weak self] buffer in
            self?.processAudio(buffer)
        }

        roleplayFeedbackObserver = NotificationCenter.default.addObserver(
            forName: .roleplayFeedbackCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleRoleplayFeedbackCompleted()
        }
    }

    private func buildProgrammaticLayout() {
        tableView?.removeFromSuperview()
        micButton?.removeFromSuperview()
        replayButton?.removeFromSuperview()
        exitButton?.removeFromSuperview()

        let newTableView = UITableView(frame: .zero, style: .plain)
        newTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newTableView)
        tableView = newTableView

        let newMicButton = UIButton(type: .system)
        newMicButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newMicButton)
        micButton = newMicButton

        let newReplayButton = UIButton(type: .system)
        newReplayButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newReplayButton)
        replayButton = newReplayButton

        let newExitButton = UIButton(type: .system)
        newExitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newExitButton)
        exitButton = newExitButton

        NSLayoutConstraint.activate([
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            micButton.widthAnchor.constraint(equalToConstant: 72),
            micButton.heightAnchor.constraint(equalToConstant: 72),

            replayButton.centerYAnchor.constraint(equalTo: micButton.centerYAnchor),
            replayButton.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -24),
            replayButton.widthAnchor.constraint(equalToConstant: 56),
            replayButton.heightAnchor.constraint(equalToConstant: 56),

            exitButton.centerYAnchor.constraint(equalTo: micButton.centerYAnchor),
            exitButton.leadingAnchor.constraint(equalTo: micButton.trailingAnchor, constant: 24),
            exitButton.widthAnchor.constraint(equalToConstant: 56),
            exitButton.heightAnchor.constraint(equalToConstant: 56),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -64),
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = AppColors.screenBackground
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = nil
    }

    private func updateStatusLabel() {
        switch currentState {
        case .idle:       statusLabel.text = "Hold mic to speak"
        case .listening:  statusLabel.text = "Listening…"
        case .processing: statusLabel.text = "Thinking…"
        case .speaking:   statusLabel.text = "Speaking…"
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = AppColors.screenBackground
        tableView.register(ProgrammaticChatBubbleCell.self, forCellReuseIdentifier: "AppMessageCell")
        tableView.register(ProgrammaticChatBubbleCell.self, forCellReuseIdentifier: "UserMessageCell")
        tableView.register(SuggestionCell.self, forCellReuseIdentifier: "SuggestionCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
    }
    
    private func setupButtons() {
        // Mic button
        UIHelper.styleCircularIconButton(micButton, symbol: "mic.fill")

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordLongPress(_:)))
        longPress.minimumPressDuration = 0.0
        micButton.addGestureRecognizer(longPress)

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

    private func setupWave() {
        for (i, layer) in waveLayers.enumerated() {
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = AppColors.primary.withAlphaComponent(1.0 - CGFloat(i) * 0.1).cgColor
            layer.lineWidth = 6
            layer.lineCap = .round
            layer.opacity = 0
            view.layer.addSublayer(layer)
        }
    }

    private func updateWave() {
        let centerY = micButton.frame.minY - 24
        let centerX = view.bounds.midX
        let totalWidth: CGFloat = 160
        let spacing = totalWidth / CGFloat(waveLayers.count + 1)

        for (i, layer) in waveLayers.enumerated() {
            let xPos = centerX - (totalWidth / 2) + spacing * CGFloat(i + 1)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: xPos, y: centerY))
            path.addLine(to: CGPoint(x: xPos, y: centerY))
            layer.path = path.cgPath
        }
    }

    private func startDisplayLink() {
        let proxy = RoleplayDisplayLinkProxy(target: self)
        displayLinkProxy = proxy
        displayLink = CADisplayLink(target: proxy, selector: #selector(RoleplayDisplayLinkProxy.step(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func updateAnimation() {
        let targetExpansion: CGFloat
        var shouldShowWave = false

        switch currentState {
        case .listening:
            targetExpansion = smoothedLevel * 60
            shouldShowWave = true
        case .speaking:
            let t = CACurrentMediaTime()
            targetExpansion = CGFloat(sin(t * 6.0) * 0.5 + 0.5) * 40
            shouldShowWave = true
        case .processing:
            let t = CACurrentMediaTime()
            targetExpansion = CGFloat(sin(t * 2.0) * 0.5 + 0.5) * 20
            shouldShowWave = true
        case .idle:
            targetExpansion = 2
            shouldShowWave = false
        }

        let targetOpacity: Float = shouldShowWave ? 1.0 : 0.0
        let centerY = micButton.frame.minY - 32
        let centerX = view.bounds.midX
        let totalWidth: CGFloat = 160
        let spacing = totalWidth / CGFloat(waveLayers.count + 1)

        for (i, layer) in waveLayers.enumerated() {
            layer.opacity += (targetOpacity - layer.opacity) * 0.15

            let xPos = centerX - (totalWidth / 2) + spacing * CGFloat(i + 1)
            let variation = CGFloat(sin(CACurrentMediaTime() * Double(4 + i) + Double(i)))
            var barHeight = max(4, targetExpansion * (0.5 + abs(variation) * 0.5))
            let centerDist = abs(CGFloat(i) - CGFloat(waveLayers.count - 1) / 2.0)
            barHeight *= max(0.2, 1.0 - (centerDist * 0.3))

            let path = UIBezierPath()
            path.move(to: CGPoint(x: xPos, y: centerY - barHeight / 2))
            path.addLine(to: CGPoint(x: xPos, y: centerY + barHeight / 2))
            layer.path = path.cgPath
        }
    }

    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted, currentState == .listening, let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }

        let rms = sqrt(sum / Float(count))
        let db = 20 * log10(max(rms, 0.000_001))
        let normalized = max(0, min(1, (db + 50) / 50))

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.smoothedLevel += (CGFloat(normalized) - self.smoothedLevel) * self.smoothingFactor
        }
    }

    @objc private func handleRecordLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            if currentState == .speaking {
                OnDeviceTTSService.shared.stopPlaying()
                isSpeaking = false
            }
            UIView.animate(withDuration: 0.2) {
                self.micButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.micButton.alpha = 0.8
            }
            startListening()
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.2) {
                self.micButton.transform = .identity
                self.micButton.alpha = 1.0
            }
            stopListeningAndProcess()
        default:
            break
        }
    }

    private func startListening() {
        guard !isProcessingResponse else { return }
        guard !AudioManager.shared.isRecording else { return }
        currentState = .listening
        AudioManager.shared.startRecording()
    }

    private func stopListeningAndProcess() {
        guard AudioManager.shared.isRecording else { return }
        currentState = .processing
        AudioManager.shared.stopRecording()
    }

    private func handleUserTranscription(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            currentState = .idle
            isProcessingResponse = false
            return
        }

        print("🎤 USER SAID:", cleaned)
        userResponded(cleaned)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWave()
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

        displayLink?.invalidate()
        displayLink = nil

        OnDeviceTTSService.shared.stopPlaying()

        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording(autoTranscribe: false)
        }

        AudioManager.shared.onAudioBuffer = nil
        AudioManager.shared.onFinalTranscription = nil
        AudioManager.shared.onRecordingStateChanged = nil

        currentState = .idle

        tabBarController?.tabBar.isHidden = false
    }

    deinit {
        displayLink?.invalidate()
        if let roleplayFeedbackObserver {
            NotificationCenter.default.removeObserver(roleplayFeedbackObserver)
        }
    }

    private func handleRoleplayFeedbackCompleted() {
        RoleplaySessionDataModel.shared.cancelSession()
        tabBarController?.tabBar.isHidden = false

        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            tabBarController?.selectedIndex = 0
        }
    }

    // MARK: - Backend Chat Roleplay

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

    private func startLLMRoleplay() {
        llmHistory.removeAll()
        roleplayTurnCount = 0
        isProcessingResponse = true

        // Show a loading indicator
        messages.append(ChatMessage(sender: .app, text: "Starting roleplay…", suggestions: nil))
        reloadTableSafely()

        Task {
            do {
                let systemPrompt = buildRoleplaySystemPrompt()
                let reply = try await sendToBackendChatForRoleplay(systemPrompt)
                await MainActor.run {
                    // Remove loading message
                    if messages.last?.text == "Starting roleplay…" {
                        messages.removeLast()
                    }
                    handleLLMResponse(reply)
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

    private func sendToBackendChatForRoleplay(_ text: String) async throws -> String {
        let systemPrompt = buildRoleplaySystemPrompt()

        var messages: [BackendChatMessage] = [
            BackendChatMessage(role: "system", content: systemPrompt)
        ]

        let historyMessages = llmHistory.suffix(8).map { item in
            BackendChatMessage(role: item.role.rawValue, content: item.text)
        }
        messages.append(contentsOf: historyMessages)
        messages.append(BackendChatMessage(role: "user", content: text))

        llmHistory.append(LLMMessage(role: .user, text: text))
        let response = try await BackendSpeechService.shared.chat(messages: messages)
        let trimmed = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw URLError(.badServerResponse)
        }
        llmHistory.append(LLMMessage(role: .assistant, text: trimmed))
        return trimmed
    }

    private func handleLLMResponse(_ response: String) {
        roleplayTurnCount += 1
        let (messageText, suggestions) = parseLLMResponse(response)
        let correctedMessage = applyPendingCorrection(to: messageText)

        messages.append(ChatMessage(sender: .app, text: correctedMessage, suggestions: nil))

        if !suggestions.isEmpty {
            messages.append(ChatMessage(sender: .suggestions, text: "", suggestions: suggestions))
        }

        reloadTableSafely()
        speakText(correctedMessage)
    }

    private func applyPendingCorrection(to assistantText: String) -> String {
        defer { pendingUserCorrection = nil }
        guard let correction = pendingUserCorrection else { return assistantText }
        let correctionLine = UtteranceCorrectionService.shared.correctionPrefix(for: correction)
        return "\(correctionLine) \(assistantText)"
    }

    private func parseLLMResponse(_ response: String) -> (String, [String]) {
        var messageText = response
        var suggestions: [String] = []

        let pattern = "(?i)\\*?\\*?SUGGESTIONS\\*?\\*?:\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count)),
           let range = Range(match.range, in: response) {
            
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
        currentState = .speaking

        // Stop any ongoing recording WITHOUT auto-transcribe to prevent
        // the callback → userResponded → advanceSession → speakText loop
        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording(autoTranscribe: false)
        }

        Task {
            do {
                try await OnDeviceTTSService.shared.speak(text: text, volumeBoost: 1.5)

                await MainActor.run {
                    self.isSpeaking = false
                    self.currentState = .idle
                    // Keep playAndRecord so both mic recording and future TTS work without session conflicts
                    let session = AVAudioSession.sharedInstance()
                    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try? session.setActive(true)
                }
            } catch {
                print("Roleplay TTS Error: \(error)")
                await MainActor.run {
                    self.isSpeaking = false
                    self.currentState = .idle
                }
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
            OnDeviceTTSService.shared.stopPlaying()
            isSpeaking = false
            currentState = .idle
            if AudioManager.shared.isRecording {
                AudioManager.shared.stopRecording()
            }
        }
    }

    @IBAction func micTapped(_ sender: UIButton) {
        // Push-to-talk is handled through long-press gesture.
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
        
        // Prevent empty messages from blowing up the UI and crashing roleplay flow
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        guard !isProcessingResponse else { return }
        isProcessingResponse = true
        currentState = .processing

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
            handleLLMUserResponse(text)
        }
    }

    // MARK: - LLM response flow

    private func handleLLMUserResponse(_ text: String) {
        pendingUserCorrection = UtteranceCorrectionService.shared.firstCorrection(in: text)

        // Show thinking indicator
        messages.append(ChatMessage(sender: .app, text: "…", suggestions: nil))
        reloadTableSafely()

        Task {
            do {
                let reply = try await sendToBackendChatForRoleplay(text)
                await MainActor.run {
                    // Remove thinking indicator
                    if messages.last?.text == "…" {
                        messages.removeLast()
                    }
                    session.currentLineIndex += 1
                    handleLLMResponse(reply)
                    isProcessingResponse = false
                    currentState = .idle

                    // Check if we should end after enough turns
                    if roleplayTurnCount >= scenario.script.count {
                        endLLMRoleplay()
                    }
                }
            } catch {
                await MainActor.run {
                    if messages.last?.text == "…" {
                        messages.removeLast()
                    }
                    pendingUserCorrection = nil
                    messages.append(ChatMessage(
                        sender: .app,
                        text: "Sorry, something went wrong. Please try again.",
                        suggestions: nil
                    ))
                    reloadTableSafely()
                    isProcessingResponse = false
                    currentState = .idle
                }
            }
        }
    }

    private func endLLMRoleplay() {
        session.status = .completed
        session.endedAt = Date()

        RoleplaySessionDataModel.shared.updateSession(session, scenario: scenario)
        
        // Calculate actual duration in minutes
        let seconds = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0

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
            if normalizedInput == normalizedOption { return true }
            
            let inputWords = normalizedInput.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            let optionWords = normalizedOption.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard !optionWords.isEmpty else { return false }
            
            // Require 80% of the expected words to be present, meaning the user reasonably said the sentence
            let intersection = Set(inputWords).intersection(Set(optionWords))
            let matchRatio = Double(intersection.count) / Double(optionWords.count)
            
            // Also ensure they didn't just string 50 random words together (limit extra words)
            let extraWordsRatio = Double(inputWords.count) / Double(optionWords.count)
            
            return matchRatio >= 0.8 && extraWordsRatio <= 1.5
        }

        if isCorrect {
            currentWrongStreak = 0
            advanceSession()
        } else {
            let correctionHint = scriptedCorrectionHint(for: text, expected: expected)
            handleWrongAttempt(expected: expected, correctionHint: correctionHint)
            isProcessingResponse = false
            currentState = .idle
        }
    }

    private func scriptedCorrectionHint(for userText: String, expected: [String]) -> String? {
        if let correction = UtteranceCorrectionService.shared.firstCorrection(in: userText) {
            return UtteranceCorrectionService.shared.correctionPrefix(for: correction)
        }

        guard let closest = closestExpectedReply(to: userText, expected: expected) else {
            return nil
        }

        return "Try this phrasing: \"\(closest)\"."
    }

    private func closestExpectedReply(to input: String, expected: [String]) -> String? {
        let inputWords = Set(normalize(input).split(separator: " ").map(String.init))
        guard !inputWords.isEmpty else { return expected.first }

        var bestOption: String?
        var bestScore = -1.0

        for option in expected {
            let optionWords = Set(normalize(option).split(separator: " ").map(String.init))
            guard !optionWords.isEmpty else { continue }
            let overlap = Double(inputWords.intersection(optionWords).count)
            let denom = Double(optionWords.count)
            let score = overlap / max(1.0, denom)
            if score > bestScore {
                bestScore = score
                bestOption = option
            }
        }

        return bestOption
    }

    private func advanceSession() {
        session.currentLineIndex += 1

        if session.currentLineIndex < scenario.script.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadCurrentStep()
                self.isProcessingResponse = false
                self.currentState = .idle
            }
        } else {
            session.status = .completed
            session.endedAt = Date()

            RoleplaySessionDataModel.shared.updateSession(session, scenario: scenario)
            
            // Calculate actual duration in minutes
            let seconds = session.endedAt?.timeIntervalSince(session.startedAt) ?? 0

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


    private func handleWrongAttempt(expected: [String], correctionHint: String?) {
        currentWrongStreak += 1
        totalWrongAttempts += 1

        let feedbackText: String
        if let correctionHint, !correctionHint.isEmpty {
            feedbackText = "\(correctionHint)\nNow try one of the options below."
        } else {
            feedbackText = "Not quite. Try one of the options below."
        }

        messages.append(
            ChatMessage(sender: .app, text: feedbackText, suggestions: nil)
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
        OnDeviceTTSService.shared.stopPlaying()
        isSpeaking = false
        currentState = .idle

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
        OnDeviceTTSService.shared.stopPlaying()
        isSpeaking = false

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
            let _ = lastAudioData
            let aiFeedbackEnabled = UserDataModel.shared.getCurrentUser()?.aiFeedbackEnabled ?? false
            let engine = FeedbackEngineFactory.makeDefault(aiFeedbackEnabled: aiFeedbackEnabled)
            let response = await engine.analyze(
                FeedbackEngineInput(
                    transcript: userTranscript,
                    topic: scenario.title,
                    durationS: durationSeconds,
                    userId: userId,
                    sessionId: sessionId,
                    mode: .roleplay,
                    turnSummaries: []
                )
            )

            await MainActor.run {
                let feedbackVC = FeedbackCollectionViewController()
                feedbackVC.transcript = userTranscript
                feedbackVC.topic = scenario.title
                feedbackVC.speakingDuration = durationSeconds
                feedbackVC.sessionId = sessionId
                feedbackVC.userId = userId
                feedbackVC.sessionMode = .roleplay
                feedbackVC.activityType = .roleplay
                feedbackVC.aiFeedbackEnabled = aiFeedbackEnabled
                feedbackVC.preloadedResponse = response

                let nav = UINavigationController(rootViewController: feedbackVC)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
        }
    }

    private func presentScoreScreen() {
        OnDeviceTTSService.shared.stopPlaying()
        isSpeaking = false

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
            ) as! ProgrammaticChatBubbleCell
            cell.configure(text: msg.text, isUser: false)
            return cell

        case .user:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "UserMessageCell",
                for: indexPath
            ) as! ProgrammaticChatBubbleCell
            cell.configure(text: msg.text, isUser: true)
            return cell

        case .suggestions:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "SuggestionCell",
                for: indexPath
            ) as! SuggestionCell
            cell.configure(msg.suggestions ?? [])
            return cell
        }
    }
}

extension RoleplayChatViewController {
    private func calculateScore() -> Int {
        let penalty = totalWrongAttempts * 5
        return max(100 - penalty, 60)
    }
}
