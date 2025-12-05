//
//  StartJamViewController.swift
//  OpenTone
//
//  Created by Student on 03/12/25.
//

import UIKit

class StartJamViewController: UIViewController {

    // TIMER OUTLETS
    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var waveView: UIView!

    // TOPIC
    @IBOutlet weak var topicTitleLabel: UILabel!

    // BUTTONS
    @IBOutlet weak var bulbButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MIC UI
    @IBOutlet weak var micContainerView: UIView!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var waveAnimationView: UIView!

    // TOPIC FROM PREVIOUS SCREEN
    var topicText: String = ""

    private let timerManager = TimerManager()
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        timerManager.delegate = self
        setupInitialUI()
        setupWaveAnimation()

        // Mic tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(micTapped))
        micContainerView.addGestureRecognizer(tap)
        micImageView.tintColor = .black

        micImageView.image = UIImage(systemName: "mic.slash.fill")
        waveAnimationView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topicTitleLabel.text = topicText
        topicTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        micContainerView.layer.cornerRadius = micContainerView.bounds.width / 2
        micContainerView.clipsToBounds = true

        // ❗ REMOVE TIMER AUTO-START — we now use Countdown screen for speech
    }

    // MARK: - MIC UI LOGIC
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

    // WAVES
    func startWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        UIView.animate(
            withDuration: 1.2,
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                self.waveAnimationView.transform = CGAffineTransform(scaleX: 1, y: 4)
            }
        )
    }

    func stopWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        waveAnimationView.transform = .identity
    }

    // MARK: - UI SETUP
    private func setupInitialUI() {
        timerLabel.text = "02:00"
        timerLabel.textColor = .black
        timerLabel.isHidden = false
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

        UIView.animate(
            withDuration: 1.2,
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                wave.transform = CGAffineTransform(scaleX: 1, y: 5)
            }
        )
    }

    // MARK: - CANCEL BUTTON
    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - START SPEECH → GO TO COUNTDOWN (SPEECH MODE)
    @IBAction func beginSpeechTapped(_ sender: UIButton) {

        guard let countdownVC = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        countdownVC.mode = .speech  // ⭐ VERY IMPORTANT

        navigationController?.pushViewController(countdownVC, animated: true)
    }
}

// MARK: - IGNORE TIMER DELEGATE (WE DO NOT AUTO-START TIMER ANYMORE)
extension StartJamViewController: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {}
    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {}
    func timerManagerDidFinish() {}
}
