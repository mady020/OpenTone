
import UIKit

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
        timerRingView.resetRing() 
        timerRingView.setProgress(value: CGFloat(remainingSeconds), max: 30) // Pause visual state

        let alert = UIAlertController(
            title: "Exit Session",
            message: "Would you like to save this session for later or exit without saving?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Resume the timer
            self.timerManager.start(from: self.remainingSeconds)
            self.timerRingView.animateRing(
                remainingSeconds: self.remainingSeconds,
                totalSeconds: 30
            )
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

        timerLabel.text = "00:00"

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.phase = .completed
        session.endedAt = Date()
        JamSessionDataModel.shared.updateActiveSession(session)

        let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Feedback")
        vc.navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = false
        navigationController?.pushViewController(vc, animated: true)
    }
}
