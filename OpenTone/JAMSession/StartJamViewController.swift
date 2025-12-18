
import UIKit

class StartJamViewController: UIViewController {

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var waveView: UIView!

    @IBOutlet weak var topicTitleLabel: UILabel!

    @IBOutlet weak var bulbButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var micContainerView: UIView!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var waveAnimationView: UIView!
    var topicText: String = ""

    private let timerManager = TimerManager()   // 2 minutes fixed (120 sec)
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.hidesBottomBarWhenPushed = true
        
        view.backgroundColor = .white

        timerManager.delegate = self
        setupInitialUI()
        setupWaveAnimation()
        let tap = UITapGestureRecognizer(target: self, action: #selector(micTapped))
        micContainerView.addGestureRecognizer(tap)

        micImageView.tintColor = .black
        micImageView.image = UIImage(systemName: "mic.slash.fill")
        waveAnimationView.isHidden = true
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        topicTitleLabel.text = topicText
        topicTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.didStart {
                self.didStart = true
                self.timerRingView.resetRing()
                self.timerRingView.animateRing(duration: 120)
                self.timerManager.start()
            }
        }
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        micContainerView.layer.cornerRadius = micContainerView.bounds.width / 2
        micContainerView.clipsToBounds = true
    }
    @objc func micTapped() {
        if waveAnimationView.isHidden {
            showWaveformState()
        } else {
            showMicOffState()
        }
    }

    func showWaveformState() {
        micImageView.isHidden = true
        waveAnimationView.isHidden = false
        startWaveAnimation()
    }

    func showMicOffState() {
        micImageView.isHidden = false
        waveAnimationView.isHidden = true
        stopWaveAnimation()
    }

    func startWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            self.waveAnimationView.transform = CGAffineTransform(scaleX: 1, y: 4)
        })
    }

    func stopWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        waveAnimationView.transform = .identity
    }
    private func setupInitialUI() {
        timerLabel.text = "02:00"
        timerLabel.textColor = .black
    }

    private func setupWaveAnimation() {
        waveView.subviews.forEach { $0.removeFromSuperview() }

        let wave = UIView(frame: CGRect(
            x: 0,
            y: waveView.bounds.midY - 1,
            width: waveView.bounds.width,
            height: 2
        ))

        wave.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
        wave.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        waveView.addSubview(wave)

        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            wave.transform = CGAffineTransform(scaleX: 1, y: 5)
        })
    }
    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func beginSpeechTapped(_ sender: UIButton) {

        guard let countdownVC = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        countdownVC.mode = .speech
        navigationController?.pushViewController(countdownVC, animated: true)
    }
}
extension StartJamViewController: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {
        timerLabel.text = "02:00"
    }

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime
    }
    
    func timerManagerDidFinish() {
        timerLabel.text = "00:00"
        StreakDataModel.shared.logSession(
            title: "2 Min Session",
            subtitle: "You completed a speaking session",
            topic: topicText,          // REAL topic user spoke on
            durationMinutes: 2,
            xp: 15,
            iconName: "mic.fill"
        )
    }

    

}
