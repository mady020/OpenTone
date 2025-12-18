
import UIKit

class StartJamViewController: UIViewController {

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var topicTitleLabel: UILabel!
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var bottomActionStackView: UIStackView!

    private let timerManager = TimerManager()
    private var remainingSeconds: Int = 120
    private var hintStackView: UIStackView?
    private var didFinishSpeech = false
    private var isMicOn = false   // only logical state, no UI handling

    override func viewDidLoad() {
        super.viewDidLoad()
        timerManager.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true


        guard let session = JamSessionDataModel.shared.getActiveSession() else { return }

        topicTitleLabel.text = session.topic
        remainingSeconds = session.secondsLeft
        timerLabel.text = format(remainingSeconds)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        timerManager.reset()
        timerRingView.resetRing()

        timerRingView.animateRing(
            remainingSeconds: remainingSeconds,
            totalSeconds: 120
        )

        timerManager.start(from: remainingSeconds)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.secondsLeft = remainingSeconds
        JamSessionDataModel.shared.updateActiveSession(session)
    }

    // MARK: - Mic Logic (NO UI code)

    @IBAction func micTapped(_ sender: UIButton) {
        isMicOn.toggle()
        // UI is handled in storyboard (selected state / images)
        // Use isMicOn later for audio / speech logic

    }

    // MARK: - Hint Logic

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

        let chip = UIView()
        chip.backgroundColor = UIColor(red: 146/255, green: 117/255, blue: 234/255, alpha: 0.12)
        chip.layer.cornerRadius = 22
        chip.layer.borderWidth = 2
        chip.layer.borderColor = UIColor(
            red: 0.42, green: 0.05, blue: 0.68, alpha: 1
        ).cgColor

        let label = UILabel()
        label.text = text
        label.textColor = .black
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

    //    @IBAction func cancelTapped(_ sender: UIButton) {
    //
    //        guard let vc = storyboard?
    //            .instantiateViewController(
    //                withIdentifier: "JamFeedbackCollectionViewController"
    //            ) as? JamFeedbackCollectionViewController else { return }
    //
    //        navigationController?.pushViewController(vc, animated: true)
    //    }
}

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

        //        guard let vc = storyboard?
        //            .instantiateViewController(
        //                withIdentifier: "JamFeedbackCollectionViewController"
        //            ) as? JamFeedbackCollectionViewController else { return }
        //
        //        navigationController?.pushViewController(vc, animated: true)

    }

    

}
