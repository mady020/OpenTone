import UIKit
import AVFoundation
import AVFAudio
import Speech

final class AICallController: UIViewController {

    // MARK: - Audio Visualisation
    private let audioEngine = AVAudioEngine()
    private var displayLink: CADisplayLink?
    private let ringLayer = CAShapeLayer()

    private var smoothedLevel: CGFloat = 0.1
    private let smoothingFactor: CGFloat = 0.15
    private let baseRadius: CGFloat = 90
    private let maxExpansion: CGFloat = 45

    private var isMuted = false
    private var isListening = false
    private var tapInstalled = false

    // MARK: - Speech / Voice
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Conversation history to send to backend for context
    // Store alternating "User: ..." and "Assistant: ..." lines
    private var conversationHistory: [String] = []

    private let backendURLString = "http://localhost:3000/chat"

    // MARK: - End-of-speech detection
    private var lastPartialText: String = ""
    private var lastPartialUpdate: Date = .distantPast
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.2 // seconds
    private let minUtteranceLength: Int = 3 // minimal characters before forcing final

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("🟢 AICallController loaded")

        view.backgroundColor = AppColors.screenBackground
        speechSynthesizer.delegate = self

        setupRing()
        setupButtons()
        setupAudioSession()
        startDisplayLink()
        requestPermissionsAndStart()
    }
    
    private func setupButtons() {
        let muteButton = makeButton( symbol: "mic.fill", action: #selector(toggleMute) )
        muteButton.frame.origin = CGPoint(x: 40, y: view.bounds.height - 120)
        let closeButton = makeButton( symbol: "xmark", action: #selector(closeTapped) )
        closeButton.frame.origin = CGPoint( x: view.bounds.width - 96, y: view.bounds.height - 120 )
        view.addSubview(muteButton)
        view.addSubview(closeButton)
    }
    
    private func makeButton(symbol: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        button.layer.cornerRadius = 28
        button.backgroundColor = AppColors.cardBackground
        button.layer.borderColor = AppColors.cardBorder.cgColor
        button.layer.borderWidth = 1
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = AppColors.textPrimary
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ringLayer.frame = view.bounds
        updateRing(radius: baseRadius)
    }

    deinit {
        print("🔴 AICallController deinit")
        displayLink?.invalidate()
        invalidateSilenceTimer()
        teardownAudio()
    }

    // MARK: - Permissions
    private func requestPermissionsAndStart() {
        print("🛂 Requesting permissions...")
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            print("🎙 Speech auth status:", status.rawValue)
            guard status == .authorized else {
                print("❌ Speech recognition not authorized")
                return
            }

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
                print("🎤 Mic permission:", granted)
                guard granted else {
                    print("❌ Microphone permission denied")
                    return
                }

                DispatchQueue.main.async {
                    self?.startListening()
                }
            }
        }
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try session.setActive(true)
            print("🔊 Audio session ready")
        } catch {
            print("❌ Audio session error:", error)
        }
    }

    private func teardownAudio() {
        print("🧹 Tearing down audio")
        stopListening()
        audioEngine.stop()
        audioEngine.reset()
    }

    // MARK: - Ring
    private func setupRing() {
        ringLayer.strokeColor = AppColors.primary.cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 8
        ringLayer.lineCap = .round
        ringLayer.opacity = 0.9
        view.layer.addSublayer(ringLayer)
    }

    private func updateRing(radius: CGFloat) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        ringLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
    }

    // MARK: - Display Link
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
        print("⏱️ Display link started")
    }

    @objc private func updateAnimation() {
        updateRing(radius: baseRadius + smoothedLevel * maxExpansion)
    }

    // MARK: - Listening
    private func startListening() {
        guard !isListening else { return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Speech recognizer unavailable")
            return
        }

        print("🎧 Start listening")
        isListening = true
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
                print("🗣 LIVE:", text)

                if result.isFinal {
                    print("✅ FINAL USER TEXT:", text)
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
            print("▶️ Audio engine started")
        } catch {
            print("❌ Audio engine start failed:", error)
            invalidateSilenceTimer()
            restartListening()
        }
    }

    private func stopListening() {
        guard isListening else { return }

        print("🛑 Stop listening")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            print("🔁 Restart listening")
            self.startListening()
        }
    }

    private func removeTap() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
            print("🧲 Removed input tap")
        }
    }

    // MARK: - Silence detection
    private func startSilenceTimer() {
        invalidateSilenceTimer()
        lastPartialUpdate = Date()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkSilence()
        }
        RunLoop.main.add(silenceTimer!, forMode: .common)
        print("⏳ Silence timer started")
    }

    private func invalidateSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    private func checkSilence() {
        guard isListening else { return }
        let elapsed = Date().timeIntervalSince(lastPartialUpdate)
        if elapsed >= silenceThreshold, lastPartialText.count >= minUtteranceLength {
            print("🤫 Silence detected (\(String(format: "%.2f", elapsed))s). Forcing final with text:", lastPartialText)
            // Force finalize
            handleFinalTranscript(lastPartialText)
        }
    }

    // MARK: - Audio Level
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

    // MARK: - Transcript Handling
    private func handleFinalTranscript(_ text: String) {
        stopListening()

        // Append user message to history
        conversationHistory.append("User: \(text)")

        sendToBackend(userText: text, history: conversationHistory) { [weak self] reply in
            guard let self else { return }

            if let reply {
                print("🤖 AI REPLY:", reply)
                // Append assistant reply to history
                self.conversationHistory.append("Assistant: \(reply)")
                DispatchQueue.main.async {
                    self.speakAI(reply)
                }
            } else {
                print("❌ Backend returned nil")
                self.restartListening()
            }
        }
    }

    // MARK: - Networking
    private func sendToBackend(userText: String, history: [String], completion: @escaping (String?) -> Void) {
        print("📡 Sending to backend:", userText)
        print("🧾 History lines:", history.count)

        guard let url = URL(string: backendURLString) else {
            print("❌ Invalid backend URL")
            completion(nil)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // The server accepts { message, history? }
        let payload: [String: Any] = [
            "message": userText,
            "history": history
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ JSON encode error:", error)
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                print("❌ Network error:", error)
                completion(nil)
                return
            }

            if let http = response as? HTTPURLResponse {
                print("🌐 HTTP status:", http.statusCode)
            }

            guard let data else {
                print("❌ No data in response")
                completion(nil)
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("📥 Raw response:", raw)
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let reply = json["reply"] as? String
            else {
                print("❌ Invalid backend JSON:", String(data: data, encoding: .utf8) ?? "")
                completion(nil)
                return
            }

            completion(reply.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }

    // MARK: - AI Speech
    private func speakAI(_ text: String) {
        guard !isMuted else {
            print("🔇 Muted, skipping speech")
            restartListening()
            return
        }

        print("🔊 Speaking AI response")
        audioEngine.stop()
        audioEngine.reset()

        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        u.rate = AVSpeechUtteranceDefaultSpeechRate

        speechSynthesizer.speak(u)
    }

    // MARK: - Actions
    @objc private func toggleMute(_ sender: UIButton) {
        isMuted.toggle()
        print(isMuted ? "🔇 Muted" : "🎤 Unmuted")

        sender.setImage(
            UIImage(systemName: isMuted ? "mic.slash.fill" : "mic.fill"),
            for: .normal
        )

        isMuted ? teardownAudio() : startListening()
    }

    @objc private func closeTapped() {
        print("❎ Close tapped")
        speechSynthesizer.stopSpeaking(at: .immediate)
        teardownAudio()
        dismiss(animated: true)
    }
}

// MARK: - Speech Delegate
extension AICallController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        print("✅ AI finished speaking")
        restartListening()
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
        print("▶️ Speech started")
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        print("⏹️ Speech cancelled")
    }
}
