import UIKit
import AVFoundation
import AVFAudio
import Speech

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

    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var isMuted = false
    private var isListening = false
    private var tapInstalled = false

    private var lastPartialText: String = ""
    private var lastPartialUpdate: Date = .distantPast
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.5
    private let minUtteranceLength: Int = 8

    // MARK: - Ring Animation

    private var displayLink: CADisplayLink?
    private let ringLayer = CAShapeLayer()
    private let pulseLayer = CAShapeLayer()

    private var smoothedLevel: CGFloat = 0.1
    private let smoothingFactor: CGFloat = 0.15
    private let baseRadius: CGFloat = 80
    private let maxExpansion: CGFloat = 40

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
        tv.allowsSelection = false
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tv
    }()

    private var muteButton: UIButton!
    private var closeButton: UIButton!

    // MARK: - Data

    private struct ChatBubble {
        enum Sender { case user, ai }
        let sender: Sender
        let text: String
    }

    private var chatBubbles: [ChatBubble] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.screenBackground
        speechSynthesizer.delegate = self

        setupRing()
        setupUI()
        setupAudioSession()
        startDisplayLink()
        requestPermissionsAndStart()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ringLayer.frame = view.bounds
        pulseLayer.frame = view.bounds
        updateRing(radius: baseRadius)
    }

    deinit {
        displayLink?.invalidate()
        invalidateSilenceTimer()
        teardownAudio()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Status label (above ring)
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(baseRadius + 40))
        ])
        currentState = .idle

        // Chat table view (below ring)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.id)
        view.addSubview(tableView)

        let ringBottom = view.bounds.midY + baseRadius + maxExpansion + 24

        // Buttons
        muteButton = makeButton(symbol: "mic.fill", action: #selector(toggleMute))
        closeButton = makeButton(symbol: "xmark", action: #selector(closeTapped))
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(muteButton)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Table view fills space between ring bottom and buttons
            tableView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: baseRadius + maxExpansion + 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: muteButton.topAnchor, constant: -16),

            // Buttons at bottom
            muteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            muteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            muteButton.widthAnchor.constraint(equalToConstant: 56),
            muteButton.heightAnchor.constraint(equalToConstant: 56),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 56),
            closeButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    private func makeButton(symbol: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 28
        button.backgroundColor = AppColors.cardBackground
        button.layer.borderColor = AppColors.cardBorder.cgColor
        button.layer.borderWidth = 1
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        button.tintColor = AppColors.textPrimary
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func updateStatusLabel() {
        switch currentState {
        case .idle:       statusLabel.text = "Tap mic to start"
        case .listening:  statusLabel.text = "Listening…"
        case .processing: statusLabel.text = "Thinking…"
        case .speaking:   statusLabel.text = "Speaking…"
        }
    }

    // MARK: - Ring Animation

    private func setupRing() {
        // Subtle pulse ring behind main ring
        pulseLayer.strokeColor = AppColors.primary.withAlphaComponent(0.2).cgColor
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.lineWidth = 12
        pulseLayer.lineCap = .round
        pulseLayer.opacity = 1
        view.layer.addSublayer(pulseLayer)

        // Main ring
        ringLayer.strokeColor = AppColors.primary.cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 8
        ringLayer.lineCap = .round
        ringLayer.opacity = 0.9
        view.layer.addSublayer(ringLayer)
    }

    private func updateRing(radius: CGFloat) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 20)
        ringLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath

        // Pulse ring slightly larger
        pulseLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius + 6,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateAnimation() {
        let targetExpansion: CGFloat
        switch currentState {
        case .listening:
            targetExpansion = smoothedLevel * maxExpansion
        case .speaking:
            // Gentle pulsing when AI speaks
            let t = CACurrentMediaTime()
            targetExpansion = CGFloat(sin(t * 3.0) * 0.3 + 0.3) * maxExpansion * 0.5
        case .processing:
            // Slow breathe when processing
            let t = CACurrentMediaTime()
            targetExpansion = CGFloat(sin(t * 1.5) * 0.15 + 0.15) * maxExpansion
        case .idle:
            targetExpansion = 0
        }

        let currentRadius = baseRadius + targetExpansion
        updateRing(radius: currentRadius)

        // Update pulse opacity based on state
        let targetOpacity: Float = (currentState == .listening) ? 1.0 : 0.4
        pulseLayer.opacity += (targetOpacity - pulseLayer.opacity) * 0.05
    }

    // MARK: - Chat

    private func addBubble(_ bubble: ChatBubble) {
        chatBubbles.append(bubble)
        let indexPath = IndexPath(row: chatBubbles.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - Permissions & Audio Session

    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }

            let requestMicPermission: (@escaping (Bool) -> Void) -> Void = { completion in
                if #available(iOS 17.0, *) {
                    AVAudioApplication.requestRecordPermission { granted in
                        completion(granted)
                    }
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        completion(granted)
                    }
                }
            }

            requestMicPermission { granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.startListening()
                }
            }
        }
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("❌ Audio session error:", error)
        }
    }

    private func teardownAudio() {
        stopListening()
        audioEngine.stop()
        audioEngine.reset()
    }

    // MARK: - Listening

    private func startListening() {
        guard !isListening else { return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        isListening = true
        currentState = .listening
        audioEngine.reset()
        lastPartialText = ""
        lastPartialUpdate = .distantPast
        startSilenceTimer()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)

        removeTap()
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudio(buffer)
        }
        tapInstalled = true

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                if !text.isEmpty, text != self.lastPartialText {
                    self.lastPartialText = text
                    self.lastPartialUpdate = Date()
                }

                if result.isFinal {
                    self.invalidateSilenceTimer()
                    self.handleFinalTranscript(text)
                    return
                }
            }

            if let error {
                print("❌ Speech recognition error:", error.localizedDescription)
                self.invalidateSilenceTimer()
                self.restartListening()
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio engine start failed:", error)
            invalidateSilenceTimer()
            restartListening()
        }
    }

    private func stopListening() {
        guard isListening else { return }
        isListening = false

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        removeTap()
        audioEngine.stop()
        invalidateSilenceTimer()
    }

    private func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.startListening()
        }
    }

    private func removeTap() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
    }

    // MARK: - Silence Detection

    private func startSilenceTimer() {
        invalidateSilenceTimer()
        lastPartialUpdate = Date()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkSilence()
        }
        RunLoop.main.add(silenceTimer!, forMode: .common)
    }

    private func invalidateSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    private func checkSilence() {
        guard isListening else { return }
        let elapsed = Date().timeIntervalSince(lastPartialUpdate)
        if elapsed >= silenceThreshold, lastPartialText.count >= minUtteranceLength {
            handleFinalTranscript(lastPartialText)
        }
    }

    // MARK: - Audio Processing (for ring animation)

    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted, let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }

        let rms = sqrt(sum / Float(count))
        let db = 20 * log10(max(rms, 0.000_001))
        let normalized = max(0, min(1, (db + 50) / 50))

        DispatchQueue.main.async {
            self.smoothedLevel += (CGFloat(normalized) - self.smoothedLevel) * self.smoothingFactor
        }
    }

    // MARK: - Gemini Integration

    private func handleFinalTranscript(_ text: String) {
        stopListening()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            restartListening()
            return
        }

        // Show user bubble
        addBubble(ChatBubble(sender: .user, text: trimmed))
        currentState = .processing

        Task {
            do {
                let reply = try await GeminiService.shared.sendMessage(trimmed)
                await MainActor.run {
                    self.addBubble(ChatBubble(sender: .ai, text: reply))
                    self.speakAI(reply)
                }
            } catch let error as GeminiService.GeminiError {
                await MainActor.run {
                    let msg: String
                    switch error {
                    case .rateLimited:
                        msg = "I need a moment to catch my breath. Please try again in a few seconds."
                    case .quotaExhausted:
                        msg = "API quota exceeded. Please check your Gemini API plan or try again later."
                    case .noAPIKey:
                        msg = "No API key found. Please add your Gemini key in Settings."
                    default:
                        msg = "Sorry, something went wrong. Please try again."
                    }
                    self.addBubble(ChatBubble(sender: .ai, text: msg))
                    print("❌ Gemini error:", error.localizedDescription)
                    self.restartListening()
                }
            } catch {
                await MainActor.run {
                    self.addBubble(ChatBubble(sender: .ai, text: "Sorry, something went wrong. Please try again."))
                    print("❌ Gemini error:", error.localizedDescription)
                    self.restartListening()
                }
            }
        }
    }

    private func speakAI(_ text: String) {
        guard !isMuted else {
            restartListening()
            return
        }

        currentState = .speaking
        audioEngine.stop()
        audioEngine.reset()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Button Actions

    @objc private func toggleMute(_ sender: UIButton) {
        isMuted.toggle()
        sender.setImage(
            UIImage(systemName: isMuted ? "mic.slash.fill" : "mic.fill",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)),
            for: .normal
        )

        if isMuted {
            speechSynthesizer.stopSpeaking(at: .immediate)
            teardownAudio()
            currentState = .idle
        } else {
            startListening()
        }
    }

    @objc private func closeTapped() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        teardownAudio()
        GeminiService.shared.resetConversation()
        dismiss(animated: true)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AICallController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        restartListening()
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {}
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {}
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
