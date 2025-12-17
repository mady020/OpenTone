//
//  StartJamViewController.swift
//  OpenTone
//
//  Created by Student on 03/12/25.
//

import UIKit

class StartJamViewController: UIViewController {

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var waveView: UIView!
    @IBOutlet weak var topicTitleLabel: UILabel!
    @IBOutlet weak var micContainerView: UIView!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var waveAnimationView: UIView!

    private let timerManager = TimerManager()
    private var didStart = false
    private var remainingSeconds: Int = 120

    override func viewDidLoad() {
        super.viewDidLoad()

        timerManager.delegate = self
        setupWaveAnimation()

        let tap = UITapGestureRecognizer(target: self, action: #selector(micTapped))
        micContainerView.addGestureRecognizer(tap)
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

        guard !didStart else { return }
        didStart = true

        timerRingView.resetRing()
        timerRingView.animateRing(duration: TimeInterval(remainingSeconds))
        timerManager.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.secondsLeft = remainingSeconds
        JamSessionDataModel.shared.updateActiveSession(session)
    }

    @objc func micTapped() {
        waveAnimationView.isHidden ? showWaveformState() : showMicOffState()
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
        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.repeat, .autoreverse]) {
            self.waveAnimationView.transform = CGAffineTransform(scaleX: 1, y: 4)
        }
    }

    func stopWaveAnimation() {
        waveAnimationView.layer.removeAllAnimations()
        waveAnimationView.transform = .identity
    }

    private func setupWaveAnimation() {
        waveView.subviews.forEach { $0.removeFromSuperview() }
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
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
        timerLabel.text = "00:00"

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.phase = .completed
        session.endedAt = Date()
        JamSessionDataModel.shared.updateActiveSession(session)
    }
}
