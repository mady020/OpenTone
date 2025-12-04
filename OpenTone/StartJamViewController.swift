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
    
    @IBOutlet weak var countdownLabel: UILabel!
    
    @IBOutlet weak var waveView: UIView!

    // TOPIC
    @IBOutlet weak var topicTitleLabel: UILabel!

    // BUTTONS
    @IBOutlet weak var bulbButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MIC UI INSIDE STACK VIEW
    @IBOutlet weak var micContainerView: UIView!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var waveAnimationView: UIView!

    // TOPIC COMING FROM PREVIOUS SCREEN
    var topicText: String = ""

    private let timerManager = TimerManager()
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()

        timerManager.delegate = self
        setupInitialUI()
        setupWaveAnimation()

        // MIC BUTTON TAP HANDLER
        let tap = UITapGestureRecognizer(target: self, action: #selector(micTapped))
        micContainerView.addGestureRecognizer(tap)
        micContainerView.isUserInteractionEnabled = true

        // Initial mic state
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

        // Make mic container perfectly circular (works inside stack view)
        micContainerView.layer.cornerRadius = micContainerView.bounds.width / 2
        micContainerView.clipsToBounds = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.didStart && self.timerRingView.bounds.width > 20 {
                self.didStart = true
                self.timerRingView.resetRing()
                self.timerRingView.animateRing(duration: 120)
                self.timerManager.start()
            }
        }
    }

    // MARK: - MIC BUTTON TOGGLE
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

    // MARK: - WAVE ANIMATION FOR MIC BUTTON
    func startWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()

        UIView.animate(
            withDuration: 1.2,
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                self.waveAnimationView.transform = CGAffineTransform(scaleX: 1, y: 4)
            },
            completion: nil
        )
    }

    func stopWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        waveAnimationView.transform = .identity
    }

    // MARK: - TIMER UI SETUP
    private func setupInitialUI() {
        timerLabel.text = "02:00"
        timerLabel.isHidden = true

        countdownLabel.text = ""
        countdownLabel.alpha = 0
        countdownLabel.isHidden = true
    }

    private func setupWaveAnimation() {
        waveView.subviews.forEach { $0.removeFromSuperview() }

        let wave = UIView(frame: CGRect(x: 0, y: waveView.bounds.midY - 1,
                                        width: waveView.bounds.width, height: 2))

        wave.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        wave.backgroundColor = UIColor(red: 143/255, green: 120/255, blue: 234/255, alpha: 0.6)

        waveView.addSubview(wave)

        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            wave.transform = CGAffineTransform(scaleX: 1, y: 5)
        })
    }

    // CANCEL BUTTON
    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - TIMER DELEGATE
extension StartJamViewController: TimerManagerDelegate {

    func timerManagerDidUpdateCountdownText(_ text: String) {
        countdownLabel.isHidden = false
        timerLabel.isHidden = true

        countdownLabel.text = text
        countdownLabel.alpha = 0
        countdownLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        UIView.animate(withDuration: 0.45, animations: {
            self.countdownLabel.alpha = 1
            self.countdownLabel.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.countdownLabel.alpha = 0
            }
        })
    }

    func timerManagerDidStartMainTimer() {
        countdownLabel.isHidden = true
        timerLabel.isHidden = false
        timerLabel.text = "02:00"

        // START MIC WAVEFORM AFTER COUNTDOWN FINISH
        showWaveformState()
    }

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime
    }

    func timerManagerDidFinish() {
        timerLabel.text = "00:00"
        // future: navigate to next screen
    }
}
