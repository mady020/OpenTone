import UIKit
import AVFoundation
import AVFAudio
import Speech

// MARK: - DisplayLinkProxy (prevents CADisplayLink → VC retain cycle)
private final class DisplayLinkProxy {
    weak var target: AICallController?
    init(target: AICallController) { self.target = target }
    @objc func step(_ link: CADisplayLink) { target?.updateAnimation() }
}

final class AICallController: UIViewController {

    // MARK: - State Machine

    private enum State {
        case idle
        case listening
        case processing
        case speaking
    }

    private var currentState: State = .idle {
        didSet { updateStatusLabel() }
    }

    // MARK: - Audio / Speech

    private var isMuted = false
    private var isListening = false
    private var isProcessing = false   // re-entry guard for handleSilenceDetected

    // VAD (Voice Activity Detection) State
    private var lastVoiceUpdate: Date = .distantPast
    private var hasSpoken = false      // true once voice level crosses threshold
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 3.5
    private let maxListenDuration: TimeInterval = 45.0  // safety cap

    /// Cached audio from the last failed turn — enables tap-to-retry.
    private var lastFailedAudioData: Data?
    private var isRetrying = false
    private var isClosing = false

    // MARK: - Wave Animation
    private var displayLink: CADisplayLink?
    private var displayLinkProxy: DisplayLinkProxy?
    private let waveLayers: [CAShapeLayer] = (0..<5).map { _ in CAShapeLayer() }
    private var smoothedLevel: CGFloat = 0.1
    private let smoothingFactor: CGFloat = 0.15

    // MARK: - UI Elements

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.allowsSelection = true
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tv
    }()

    private var recordButton: UIButton!
    private var closeButton: UIButton!
    
    // Add a loading overlay view for when we are dismissing/getting feedback
    private let loadingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.screenBackground.withAlphaComponent(0.9)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = AppColors.primary
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Generating Feedback..."
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.primary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Data

    private struct ChatBubble {
        enum Sender { case user, ai }
        let sender: Sender
        let text: String
    }

    private var chatBubbles: [ChatBubble] = []
    private var sessionTurnSummaries: [SessionTurnSummary] = []
    private var userTranscriptParts: [String] = []
    private var hasStartedConversation = false
    private let aiCallScenario = "Open Conversation"
    private let aiCallDifficulty = "medium"
    private let aiCallOrchestrator = AICallProviderFactory.makeOrchestrator()

    /// Conversation history sent to Ollama (/chat endpoint treats text turns).
    /// Each entry: ["role": "user"|"assistant", "content": "…"]
    private var conversationHistory: [[String: String]] = []

    /// Timestamp when the call started — used to compute call duration.
    private var callStartDate: Date = Date()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground

        setupWave()
        setupUI()
        
        AudioManager.shared.onAudioBuffer = { [weak self] buffer in
            self?.processAudio(buffer)
        }

        startDisplayLink()
        AudioManager.shared.requestPermissions { [weak self] granted in
            guard let self, granted else { return }
            self.beginSession()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWave()
    }

    deinit {
        displayLink?.invalidate()
        OnDeviceTTSService.shared.stopPlaying()
        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording(autoTranscribe: false)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Status label (above chat)
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        currentState = .idle

        // Chat table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.id)
        view.addSubview(tableView)

        // Buttons
        recordButton = makeButton(symbol: "mic.fill", action: nil)
        closeButton = makeButton(symbol: "xmark", action: #selector(closeTapped))
        
        // Setup long press for record button
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordLongPress(_:)))
        longPress.minimumPressDuration = 0.0 // trigger immediately on touch down
        recordButton.addGestureRecognizer(longPress)
        
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        view.addSubview(closeButton)
        
        // Setup overlay on top
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingIndicator)
        loadingOverlay.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            // Table view fills space between status label and top of wave animation
            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -64),

            // Buttons at bottom
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            recordButton.widthAnchor.constraint(equalToConstant: 72),
            recordButton.heightAnchor.constraint(equalToConstant: 72),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            closeButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 56),
            closeButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Loading Overlay Constraints
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor, constant: -20),
            
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor)
        ])
    }

    private func makeButton(symbol: String, action: Selector?) -> UIButton {
        let button = UIButton(type: .system)
        UIHelper.styleCircularIconButton(button, symbol: symbol)
        if let action = action {
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        return button
    }

    private func updateStatusLabel() {
        switch currentState {
        case .idle:       statusLabel.text = "Hold mic to speak"
        case .listening:  statusLabel.text = "Listening…"
        case .processing: statusLabel.text = "Thinking…"
        case .speaking:   statusLabel.text = "Speaking…"
        }
    }

    // MARK: - Wave Animation

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
        let centerY = recordButton.frame.minY - 24
        let centerX = view.bounds.midX
        let totalWidth: CGFloat = 160
        let spacing = totalWidth / CGFloat(waveLayers.count + 1)
        
        for (i, layer) in waveLayers.enumerated() {
            let xPos = centerX - (totalWidth / 2) + spacing * CGFloat(i + 1)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: xPos, y: centerY))
            path.addLine(to: CGPoint(x: xPos, y: centerY)) // initial zero height
            layer.path = path.cgPath
        }
    }

    private func startDisplayLink() {
        let proxy = DisplayLinkProxy(target: self)
        displayLinkProxy = proxy
        displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.step(_:)))
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
        
        let centerY = recordButton.frame.minY - 32
        let centerX = view.bounds.midX
        let totalWidth: CGFloat = 160
        let spacing = totalWidth / CGFloat(waveLayers.count + 1)

        for (i, layer) in waveLayers.enumerated() {
            layer.opacity += (targetOpacity - layer.opacity) * 0.15
            
            let xPos = centerX - (totalWidth / 2) + spacing * CGFloat(i + 1)
            
            // create variation between bars
            let variation = CGFloat(sin(CACurrentMediaTime() * Double(4 + i) + Double(i)))
            var barHeight = max(4, targetExpansion * (0.5 + abs(variation) * 0.5))
            
            // middle bars are taller
            let centerDist = abs(CGFloat(i) - CGFloat(waveLayers.count - 1)/2.0)
            barHeight *= max(0.2, 1.0 - (centerDist * 0.3))

            let path = UIBezierPath()
            path.move(to: CGPoint(x: xPos, y: centerY - barHeight/2))
            path.addLine(to: CGPoint(x: xPos, y: centerY + barHeight/2))
            layer.path = path.cgPath
        }
    }

    // MARK: - Chat

    private func addBubble(_ bubble: ChatBubble) {
        chatBubbles.append(bubble)
        let indexPath = IndexPath(row: chatBubbles.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - Permissions & Audio Session

    private func teardownAudio() {
        AudioManager.shared.onAudioBuffer = nil
        if AudioManager.shared.isRecording {
            AudioManager.shared.stopRecording(autoTranscribe: false)
        }
        OnDeviceTTSService.shared.stopPlaying()
    }

    // MARK: - Listening

    private func startListening() {
        guard !isListening else { return }

        isListening = true
        isProcessing = false
        currentState = .listening

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)
        
        AudioManager.shared.startRecording()
    }

    private func stopListeningAndProcess() {
        guard isListening else { return }
        isListening = false
        AudioManager.shared.stopRecording(autoTranscribe: false)
        handleSilenceDetected() // trigger processing manually on button release
    }

    private func stopListening() {
        guard isListening else { return }
        isListening = false
        AudioManager.shared.stopRecording(autoTranscribe: false)
    }

    private func restartListening() {
        stopListening()
        // Wait for push-to-talk to trigger
        currentState = .idle
    }

    // MARK: - Silence Detection (Disabled for PTT)

    private func startSilenceTimer() {}
    private func invalidateSilenceTimer() {}
    private func checkSilence() {}

    // MARK: - Audio Processing (for wave animation)

    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted, currentState == .listening, let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }

        let rms = sqrt(sum / Float(count))
        let db = 20 * log10(max(rms, 0.000_001))
        let normalized = max(0, min(1, (db + 50) / 50)) // 0.0 to 1.0

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.smoothedLevel += (CGFloat(normalized) - self.smoothedLevel) * self.smoothingFactor
            
            // Voice detected — mark as spoken and reset silence timer
            if self.smoothedLevel > 0.12 {
                self.hasSpoken = true
                self.lastVoiceUpdate = Date()
            }
        }
    }

    // MARK: - Backend Integration

    private func beginSession() {
        guard !hasStartedConversation else { return }
        hasStartedConversation = true
        isProcessing = true
        currentState = .processing

        Task { [weak self] in
            guard let self, !self.isClosing else { return }
            let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "demo"
            do {
                let startResult = try await self.aiCallOrchestrator.startSession(
                    input: AICallStartInput(
                        userId: userId,
                        scenario: self.aiCallScenario,
                        difficulty: self.aiCallDifficulty
                    )
                )

                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    let aiText = startResult.assistantText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !aiText.isEmpty {
                        self.conversationHistory.append(["role": "assistant", "content": aiText])
                        self.addBubble(ChatBubble(sender: .ai, text: aiText))
                    }

                    if !aiText.isEmpty {
                        self.speakAI(text: aiText)
                    } else {
                        self.isProcessing = false
                        self.currentState = .idle // Instead of auto listening
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    let fallback = "AI service is unavailable right now. Please try again in a moment."
                    self.conversationHistory.append(["role": "assistant", "content": fallback])
                    self.addBubble(ChatBubble(sender: .ai, text: fallback))

                    self.speakAI(text: fallback)
                }
            }
        }
    }

    private func handleSilenceDetected() {
        guard !isProcessing, !isClosing else { return }  // prevent re-entry
        isProcessing = true

        stopListening()
        
        guard let url = AudioManager.shared.lastRecordingURL, 
              let data = try? Data(contentsOf: url),
              data.count > 1000 else {
            isProcessing = false
            currentState = .idle // Fallback to idle
            return
        }

        currentState = .processing

        Task { [weak self] in
            guard let self, !self.isClosing else { return }
            
            // Get local transcription first
            var transcript = ""
            await withCheckedContinuation { continuation in
                AudioManager.shared.transcribeFile(at: url) { text in
                    transcript = text ?? ""
                    continuation.resume()
                }
            }
            
            if transcript.isEmpty {
                await MainActor.run {
                    self.currentState = .idle
                    self.isProcessing = false
                }
                return
            }
            
            do {
                let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "demo"
                let durationS = 5.0
                let result = try await self.aiCallOrchestrator.generateTurn(
                    input: AICallTurnInput(
                        userId: userId,
                        transcript: transcript,
                        durationS: durationS,
                        scenario: self.aiCallScenario,
                        difficulty: self.aiCallDifficulty,
                        conversationHistory: self.conversationHistory
                    )
                )

                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    let userText = result.userTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !userText.isEmpty {
                        self.addBubble(ChatBubble(sender: .user, text: userText))
                        self.conversationHistory.append(["role": "user", "content": userText])
                        self.userTranscriptParts.append(userText)
                        self.sessionTurnSummaries.append(self.buildTurnSummary(
                            transcript: userText,
                            durationS: durationS,
                            metrics: result.metrics
                        ))
                    }

                    let aiText = result.assistantText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Could you say that again?"
                        : result.assistantText
                    self.conversationHistory.append(["role": "assistant", "content": aiText])
                    self.addBubble(ChatBubble(sender: .ai, text: aiText))
                    
                    if !aiText.isEmpty {
                        self.speakAI(text: aiText)
                    } else {
                        self.isProcessing = false
                        self.currentState = .idle
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    print("❌ Backend error:", error.localizedDescription)
                    self.lastFailedAudioData = data
                    self.isRetrying = false
                    let msg = "⚠️ Connection issue — tap here to retry, or hold mic to continue."
                    self.addBubble(ChatBubble(sender: .ai, text: msg))
                    self.isProcessing = false
                    self.currentState = .idle
                }
            }
        }
    }
    
    /// Retry the last failed conversation turn using cached audio data.
    private func retryLastTurn() {
        guard let cachedAudio = lastFailedAudioData, !isRetrying else { return }
        isRetrying = true
        lastFailedAudioData = nil
        isProcessing = true
        stopListening()
        currentState = .processing

        // Remove the retry-prompt bubble
        if let last = chatBubbles.last, last.sender == .ai, last.text.contains("tap here to retry") {
            chatBubbles.removeLast()
            tableView.deleteRows(at: [IndexPath(row: chatBubbles.count, section: 0)], with: .fade)
        }

        Task { [weak self] in
            guard let self, !self.isClosing else { return }
            
            // Re-transcribe the cached audio
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")
            try? cachedAudio.write(to: tempURL)
            
            var transcript = ""
            await withCheckedContinuation { continuation in
                AudioManager.shared.transcribeFile(at: tempURL) { text in
                    transcript = text ?? ""
                    continuation.resume()
                }
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
            
            if transcript.isEmpty {
                await MainActor.run {
                    self.currentState = .idle
                    self.isProcessing = false
                    self.isRetrying = false
                }
                return
            }
            
            do {
                let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "demo"
                let durationS = 5.0
                let result = try await self.aiCallOrchestrator.generateTurn(
                    input: AICallTurnInput(
                        userId: userId,
                        transcript: transcript,
                        durationS: durationS,
                        scenario: self.aiCallScenario,
                        difficulty: self.aiCallDifficulty,
                        conversationHistory: self.conversationHistory
                    )
                )

                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    self.isRetrying = false
                    let userText = result.userTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !userText.isEmpty {
                        self.addBubble(ChatBubble(sender: .user, text: userText))
                        self.conversationHistory.append(["role": "user", "content": userText])
                        self.userTranscriptParts.append(userText)
                        self.sessionTurnSummaries.append(self.buildTurnSummary(
                            transcript: userText,
                            durationS: durationS,
                            metrics: result.metrics
                        ))
                    }

                    let aiText = result.assistantText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Could you say that again?"
                        : result.assistantText
                    self.conversationHistory.append(["role": "assistant", "content": aiText])
                    self.addBubble(ChatBubble(sender: .ai, text: aiText))

                    if !aiText.isEmpty {
                        self.speakAI(text: aiText)
                    } else {
                        self.isProcessing = false
                        self.currentState = .idle
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    self.isRetrying = false
                    self.lastFailedAudioData = cachedAudio
                    let msg = "Still having trouble — tap here to retry or hold mic to continue."
                    self.addBubble(ChatBubble(sender: .ai, text: msg))
                    self.isProcessing = false
                    self.currentState = .idle
                }
            }
        }
    }

    private func speakAI(text: String) {
        currentState = .speaking

        Task { [weak self] in
            guard let self, !self.isClosing else { return }
            do {
                // Use a professional/neutral persona for the AI coach voice
                try await OnDeviceTTSService.shared.speak(
                    text: text,
                    persona: .professional
                )
                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    // Transition from speaking → listening.
                    currentState = .idle
                    isProcessing = false
                    restartListening()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, !self.isClosing else { return }
                    print("❌ On-device TTS failed:", error)
                    isProcessing = false
                    currentState = .idle
                }
            }
        }
    }


    private func buildTurnSummary(transcript: String, durationS: Double, metrics: SpeechMetrics?) -> SessionTurnSummary {
        if let metrics {
            return SessionTurnSummary(
                transcript: transcript,
                totalWords: metrics.totalWords,
                durationS: metrics.durationS,
                fillers: metrics.fillers,
                pauses: metrics.pauses,
                avgPauseS: metrics.avgPauseS,
                veryLongPauses: metrics.veryLongPauses,
                repetitions: metrics.repetitions,
                fillerExamples: metrics.fillerExamples,
                pauseExamples: metrics.pauseExamples
            )
        }

        let words = transcript
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let fillerLexicon: Set<String> = ["um", "uh", "like", "actually", "basically"]
        let fillerCount = words.filter { fillerLexicon.contains($0) }.count
        let repetitions = zip(words, words.dropFirst()).reduce(0) { $1.0 == $1.1 ? $0 + 1 : $0 }

        let punctuationPauses = transcript.filter { ",.;?!".contains($0) }.count
        let inferredPauses = min(max(0, punctuationPauses / 2), max(words.count / 3, 0))
        let avgPauseS = inferredPauses > 0 ? max(0.6, (durationS * 0.15) / Double(inferredPauses)) : 0
        let veryLongPauses = avgPauseS > 1.5 ? min(inferredPauses, 1) : 0

        return SessionTurnSummary(
            transcript: transcript,
            totalWords: words.count,
            durationS: durationS,
            fillers: fillerCount,
            pauses: inferredPauses,
            avgPauseS: avgPauseS,
            veryLongPauses: veryLongPauses,
            repetitions: repetitions,
            fillerExamples: [],
            pauseExamples: []
        )
    }

    // MARK: - Button Actions

    @objc private func handleRecordLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            if currentState == .speaking {
                OnDeviceTTSService.shared.stopPlaying()
            }
            UIView.animate(withDuration: 0.2) {
                self.recordButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.recordButton.alpha = 0.8
            }
            startListening()
            
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.2) {
                self.recordButton.transform = .identity
                self.recordButton.alpha = 1.0
            }
            stopListeningAndProcess()
            
        default:
            break
        }
    }

    @objc private func closeTapped() {
        guard !isClosing else { return }
        isClosing = true
        recordButton.isEnabled = false
        closeButton.isEnabled = false
        displayLink?.invalidate()
        displayLink = nil

        OnDeviceTTSService.shared.stopPlaying()
        teardownAudio()
        
        // Show loading overlay
        loadingOverlay.isHidden = false
        loadingOverlay.alpha = 0
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.3) {
            self.loadingOverlay.alpha = 1
        }

        let turnSummaries = sessionTurnSummaries
        sessionTurnSummaries = []

        let duration = Date().timeIntervalSince(callStartDate)
        guard duration > 1, let user = UserDataModel.shared.getCurrentUser() else {
            conversationHistory.removeAll()
            userTranscriptParts.removeAll()
            
            // Hide loading overlay before dismissing
            loadingIndicator.stopAnimating()
            loadingOverlay.isHidden = true
            
            dismiss(animated: true)
            return
        }

        let userId = user.id

        // Persist call record to Supabase
        CallRecordDataModel.shared.logCall(
            userId: userId,
            duration: duration
        )

        // Build the full user transcript from preserved user turns.
        let fullTranscript = userTranscriptParts.joined(separator: " ")

        guard !fullTranscript.isEmpty || !turnSummaries.isEmpty else {
            conversationHistory.removeAll()
            userTranscriptParts.removeAll()
            
            // Hide loading overlay before dismissing
            loadingIndicator.stopAnimating()
            loadingOverlay.isHidden = true
            
            dismiss(animated: true)
            return
        }

        let sessionId = UUID().uuidString
        conversationHistory.removeAll()
        userTranscriptParts.removeAll()

        // Analyze feedback locally and optionally enhance wording with remote providers.
        currentState = .processing
        Task {
            let aiFeedbackEnabled = UserDataModel.shared.getCurrentUser()?.aiFeedbackEnabled ?? false
            let engine = FeedbackEngineFactory.makeDefault(aiFeedbackEnabled: aiFeedbackEnabled)
            let response = await engine.analyze(
                FeedbackEngineInput(
                    transcript: fullTranscript,
                    topic: "Open Conversation",
                    durationS: duration,
                    userId: userId.uuidString,
                    sessionId: sessionId,
                    mode: .aiCall,
                    turnSummaries: turnSummaries
                )
            )

            let sessionFeedback = FeedbackMapper.toSessionFeedback(
                response,
                sessionId: UUID(uuidString: sessionId) ?? UUID()
            )

            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.loadingOverlay.isHidden = true

                HistoryDataModel.shared.logActivity(
                    type: .aiCall,
                    title: "AI Call",
                    topic: "Open Conversation",
                    duration: max(1, Int(duration) / 60),
                    imageURL: "Call",
                    xpEarned: 10,
                    isCompleted: true,
                    feedback: sessionFeedback
                )

                let feedbackVC = FeedbackCollectionViewController()
                feedbackVC.transcript = fullTranscript
                feedbackVC.topic = "AI Call"
                feedbackVC.speakingDuration = duration
                feedbackVC.sessionId = sessionId
                feedbackVC.userId = userId.uuidString
                feedbackVC.sessionMode = .aiCall
                feedbackVC.activityType = .aiCall
                feedbackVC.aiFeedbackEnabled = aiFeedbackEnabled
                feedbackVC.preloadedResponse = response

                let nav = UINavigationController(rootViewController: feedbackVC)
                nav.modalPresentationStyle = .fullScreen
                if let presenter = self.presentingViewController {
                    self.dismiss(animated: false) {
                        presenter.present(nav, animated: true)
                    }
                } else {
                    self.present(nav, animated: true)
                }
            }
        }
    }

    // MARK: - Local Fallback Helpers

    /// Build a SessionFeedback from locally-collected turn summaries when the backend is unreachable.
    private func buildLocalFallbackFeedback(
        turnSummaries: [SessionTurnSummary],
        fullTranscript: String,
        duration: TimeInterval,
        sessionId: String
    ) -> SessionFeedback {
        let totalFillers = turnSummaries.reduce(0) { $0 + $1.fillers }
        let totalPauses = turnSummaries.reduce(0) { $0 + $1.pauses }
        let totalWords = turnSummaries.reduce(0) { $0 + $1.totalWords }
        let wpm = duration > 0 ? Double(totalWords) / (duration / 60.0) : 0
        let fluency = max(0, min(100, 85 - Double(totalFillers) * 3 - Double(totalPauses) * 2))

        return SessionFeedback(
            id: UUID().uuidString,
            sessionId: UUID(uuidString: sessionId) ?? UUID(),
            fillerWordCount: totalFillers,
            mispronouncedWords: [],
            fluencyScore: fluency,
            onTopicScore: max(50, fluency - 5),
            confidenceScore: nil,
            clarityScore: nil,
            overallScore: fluency,
            pauses: totalPauses,
            summary: "Session completed (\(turnSummaries.count) turns, \(Int(wpm)) WPM). Feedback computed locally.",
            createdAt: Date()
        )
    }

    /// Build a SpeechAnalysisResponse from locally-collected turn summaries for the feedback screen.
    private func buildLocalFallbackResponse(
        turnSummaries: [SessionTurnSummary],
        fullTranscript: String,
        duration: TimeInterval
    ) -> SpeechAnalysisResponse {
        let totalWords = turnSummaries.reduce(0) { $0 + $1.totalWords }
        let totalFillers = turnSummaries.reduce(0) { $0 + $1.fillers }
        let totalPauses = turnSummaries.reduce(0) { $0 + $1.pauses }
        let totalVeryLongPauses = turnSummaries.reduce(0) { $0 + $1.veryLongPauses }
        let totalRepetitions = turnSummaries.reduce(0) { $0 + $1.repetitions }
        let durationS = duration > 0 ? duration : 30.0
        let wpm = durationS > 0 ? Double(totalWords) / (durationS / 60.0) : 0
        let fillerRate = durationS > 0 ? Double(totalFillers) / durationS * 60.0 : 0
        let avgPause: Double = {
            let pauseTurns = turnSummaries.filter { $0.pauses > 0 }
            guard !pauseTurns.isEmpty else { return 0 }
            return pauseTurns.reduce(0.0) { $0 + $1.avgPauseS } / Double(pauseTurns.count)
        }()

        let metrics = SpeechMetrics(
            wpm: wpm,
            totalWords: totalWords,
            durationS: durationS,
            fillerRatePerMin: fillerRate,
            fillers: totalFillers,
            pauses: totalPauses,
            avgPauseS: avgPause,
            veryLongPauses: totalVeryLongPauses,
            repetitions: totalRepetitions,
            fillerExamples: [],
            pauseExamples: []
        )

        let fluency = max(0, min(100, 85 - Double(totalFillers) * 3 - Double(totalRepetitions) * 5))
        let confidence = max(0, min(100, wpm >= 100 && wpm <= 170 ? 80 : 60))
        let clarity = max(0, min(100, 80 - Double(totalVeryLongPauses) * 5 - Double(totalRepetitions) * 4))

        let coaching = SpeechCoaching(
            scores: CoachingScores(fluency: fluency, confidence: Double(confidence), clarity: clarity),
            primaryIssue: totalFillers > 5 ? "Reduce filler words to improve fluency." : "Keep practising for smoother speech.",
            primaryIssueTitle: totalFillers > 5 ? "Filler Words" : "General Practice",
            secondaryIssues: [],
            strengths: totalWords > 50 ? ["Good amount of speaking"] : [],
            suggestions: ["Try to reduce filler words", "Practice speaking at a steady pace"],
            evidence: [],
            llmCoaching: nil
        )

        let progress = SpeechProgress(
            deltas: Deltas(wpm: 0, fillers: 0, pauses: 0),
            overallDirection: "mixed",
            weeklySummary: "Session completed (offline feedback)."
        )

        return SpeechAnalysisResponse(
            transcript: fullTranscript,
            metrics: metrics,
            coaching: coaching,
            progress: progress
        )
    }
}

// MARK: - UITableViewDataSource & Delegate

extension AICallController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatBubbles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.id, for: indexPath) as! ChatBubbleCell
        let bubble = chatBubbles[indexPath.row]
        cell.configure(text: bubble.text, isUser: bubble.sender == .user)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bubble = chatBubbles[indexPath.row]
        if bubble.sender == .ai, bubble.text.contains("tap here to retry"), lastFailedAudioData != nil {
            retryLastTurn()
        }
    }
}

// MARK: - Chat Bubble Cell

private final class ChatBubbleCell: UITableViewCell {

    static let id = "ChatBubbleCell"

    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let senderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(senderLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            senderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            senderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            bubbleView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, isUser: Bool) {
        messageLabel.text = text

        // Deactivate both, then activate the correct one
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false

        if isUser {
            trailingConstraint.isActive = true
            bubbleView.backgroundColor = AppColors.primary
            messageLabel.textColor = .white
            senderLabel.text = "You"
            senderLabel.textColor = AppColors.primary
            senderLabel.textAlignment = .right
        } else {
            leadingConstraint.isActive = true
            bubbleView.backgroundColor = AppColors.cardBackground
            bubbleView.layer.borderColor = AppColors.cardBorder.cgColor
            bubbleView.layer.borderWidth = 1
            messageLabel.textColor = AppColors.textPrimary
            senderLabel.text = "AI"
            senderLabel.textColor = .secondaryLabel
            senderLabel.textAlignment = .left
        }
    }
}
