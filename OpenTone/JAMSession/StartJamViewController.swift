
import UIKit
import Speech
import AVFoundation

class StartJamViewController: UIViewController {

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var topicHeaderLabel: UILabel!
    @IBOutlet weak var topicTitleLabel: UILabel!
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var bottomActionStackView: UIStackView!

    private let timerManager = TimerManager(totalSeconds: 30)
    private var remainingSeconds: Int = 30
    private var hintStackView: UIStackView?
    private var didFinishSpeech = false
    private var isMicOn = false

    // MARK: - Speech Recognition

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Accumulated transcript from the user's speech.
    private var currentTranscript: String = ""
    /// Tracks whether recording has been started at least once.
    private var hasStartedRecording = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        timerManager.delegate = self
        navigationItem.hidesBackButton = true

        // Custom back button that triggers exit alert
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = AppColors.primary
        navigationItem.leftBarButtonItem = backButton

        // Load topic from active session
        if let session = JamSessionDataModel.shared.getActiveSession() {
            topicTitleLabel.text = session.topic
            remainingSeconds = 30  // Speaking always gets full 30 seconds
        }

        // Mark the speaking phase in the data model
        JamSessionDataModel.shared.beginSpeakingPhase()

        applyDarkModeStyles()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: StartJamViewController, _) in
            self.applyDarkModeStyles()
        }

        // Request speech recognition & microphone permissions, then start recording
        requestSpeechPermissions()
    }

    private func applyDarkModeStyles() {
        view.backgroundColor = AppColors.screenBackground
        timerRingView.superview?.backgroundColor = AppColors.screenBackground
        timerRingView.backgroundColor = AppColors.screenBackground
        topicTitleLabel.textColor = AppColors.textPrimary
        topicHeaderLabel?.textColor = AppColors.primary
        timerLabel.textColor = AppColors.textPrimary

        let isDark = traitCollection.userInterfaceStyle == .dark
        let buttonBg = isDark
            ? UIColor.tertiarySystemGroupedBackground
            : AppColors.primaryLight

        for case let button as UIButton in bottomActionStackView.arrangedSubviews {
            if var config = button.configuration {
                config.background.backgroundColor = buttonBg
                button.configuration = config
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        timerLabel.text = format(remainingSeconds)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        timerManager.reset()
        timerRingView.resetRing()
        timerRingView.animateRing(
            remainingSeconds: remainingSeconds,
            totalSeconds: 30
        )
        timerManager.start(from: remainingSeconds)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerManager.reset()
        stopRecording()

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.secondsLeft = remainingSeconds
        JamSessionDataModel.shared.updateActiveSession(session)
    }

    // MARK: - Navigation

    @objc private func backButtonTapped() {
        showExitAlert()
    }

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        showExitAlert()
    }

    private func showExitAlert() {
        timerManager.pause()
        pauseRecording()
        timerRingView.resetRing() 
        timerRingView.setProgress(value: CGFloat(remainingSeconds), max: 30) // Pause visual state

        let alert = UIAlertController(
            title: "Exit Session",
            message: "Would you like to save this session for later or exit without saving?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Resume the timer and recording
            self.timerManager.start(from: self.remainingSeconds)
            self.timerRingView.animateRing(
                remainingSeconds: self.remainingSeconds,
                totalSeconds: 30
            )
            self.resumeRecording()
        })

        alert.addAction(UIAlertAction(title: "Save & Exit", style: .default) { _ in
            if var session = JamSessionDataModel.shared.getActiveSession() {
                session.secondsLeft = self.remainingSeconds
                JamSessionDataModel.shared.updateActiveSession(session)
            }
            JamSessionDataModel.shared.saveSessionForLater()
            self.navigateBackToRoot()
        })

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
            self.navigateBackToRoot()
        })

        present(alert, animated: true)
    }

    private func navigateBackToRoot() {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Actions

    @IBAction func micTapped(_ sender: UIButton) {
        isMicOn.toggle()

        if isMicOn {
            // Mic is now ON — resume/start recording
            if hasStartedRecording {
                resumeRecording()
            } else {
                startRecording()
            }
            sender.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            sender.tintColor = AppColors.primary
        } else {
            // Mic is now OFF — pause recording
            pauseRecording()
            sender.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
            sender.tintColor = .systemRed
        }
    }

    @IBAction func hintTapped(_ sender: UIButton) {
        hintStackView == nil ? showHints() : removeHints()
    }

    private func showHints() {
        removeHints()

        let hints = JamSessionDataModel.shared.generateSpeakingHints()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .leading

        view.addSubview(stack)
        view.bringSubviewToFront(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomActionStackView.topAnchor, constant: -15),
            stack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])

        hintStackView = stack
        hints.forEach { stack.addArrangedSubview(createHintChip(text: $0)) }
    }

    private func createHintChip(text: String) -> UIView {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let chip = UIView()
        chip.backgroundColor = isDark
            ? AppColors.primary.withAlphaComponent(0.20)
            : AppColors.primary.withAlphaComponent(0.12)
        chip.layer.cornerRadius = 22
        chip.layer.borderWidth = 2
        chip.layer.borderColor = AppColors.primary.cgColor

        let label = UILabel()
        label.text = text
        label.textColor = AppColors.textPrimary
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0

        chip.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -16)
        ])

        return chip
    }

    private func removeHints() {
        hintStackView?.removeFromSuperview()
        hintStackView = nil
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Speech Recognition

    private func requestSpeechPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.startRecording()
                case .denied, .restricted, .notDetermined:
                    print("⚠️ Speech recognition not authorized: \(status.rawValue)")
                @unknown default:
                    break
                }
            }
        }
    }

    private func startRecording() {
        // Cancel any running task
        recognitionTask?.cancel()
        recognitionTask = nil

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("⚠️ Speech recognizer not available")
            return
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.currentTranscript = result.bestTranscription.formattedString
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isMicOn = true
            hasStartedRecording = true
            updateMicButtonAppearance()
        } catch {
            print("⚠️ Audio engine start failed: \(error)")
        }
    }

    private func pauseRecording() {
        if audioEngine.isRunning {
            audioEngine.pause()
        }
    }

    private func resumeRecording() {
        if !audioEngine.isRunning && hasStartedRecording {
            do {
                try audioEngine.start()
                isMicOn = true
                updateMicButtonAppearance()
            } catch {
                print("⚠️ Audio engine resume failed: \(error)")
            }
        }
    }

    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isMicOn = false
    }

    private func updateMicButtonAppearance() {
        // Find the mic button in the bottom stack view
        for case let button as UIButton in bottomActionStackView.arrangedSubviews {
            if button.currentImage == UIImage(systemName: "mic.fill") ||
               button.currentImage == UIImage(systemName: "mic.slash.fill") {
                if isMicOn {
                    button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                    button.tintColor = AppColors.primary
                } else {
                    button.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
                    button.tintColor = .systemRed
                }
                break
            }
        }
    }
}

// MARK: - TimerManagerDelegate

extension StartJamViewController: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {}

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime

        let parts = formattedTime.split(separator: ":")
        if parts.count == 2,
           let min = Int(parts[0]),
           let sec = Int(parts[1]) {
            remainingSeconds = min * 60 + sec
        }
    }

    func timerManagerDidFinish() {
        guard !didFinishSpeech else { return }
        didFinishSpeech = true

        // Stop recording and capture the final transcript
        let transcript = currentTranscript
        stopRecording()

        timerLabel.text = "00:00"

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.phase = .completed
        session.endedAt = Date()
        JamSessionDataModel.shared.updateActiveSession(session)

        // Calculate speaking duration
        let speakingDuration: Double
        if let start = session.startedSpeakingAt {
            speakingDuration = Date().timeIntervalSince(start)
        } else {
            speakingDuration = 30.0
        }

        let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Feedback") as! FeedbackCollectionViewController
        vc.navigationItem.hidesBackButton = true

        // Pass transcript and topic for Gemini analysis
        vc.transcript = transcript
        vc.topic = session.topic
        vc.speakingDuration = speakingDuration

        tabBarController?.tabBar.isHidden = false
        navigationController?.pushViewController(vc, animated: true)
    }
}
