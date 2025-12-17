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

    @IBOutlet weak var bulbButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MIC UI
    @IBOutlet weak var micContainerView: UIView!
    @IBOutlet weak var micImageView: UIImageView!
    @IBOutlet weak var waveAnimationView: UIView!

    // TOPIC FROM PREVIOUS SCREEN
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

        // Mic toggle setup
        let tap = UITapGestureRecognizer(target: self, action: #selector(micTapped))
        micContainerView.addGestureRecognizer(tap)

        micImageView.tintColor = .black
        micImageView.image = UIImage(systemName: "mic.slash.fill")
        waveAnimationView.isHidden = true
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
        // ⭐ FIX: Topic text visible & styled
        topicTitleLabel.text = topicText
        topicTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // ⭐ EXACT SAME LOGIC AS TIMER CELL
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.didStart {
                self.didStart = true

                // Reset & animate ring
                self.timerRingView.resetRing()
                self.timerRingView.animateRing(duration: 120)

                // Start timer countdown
                self.timerManager.start()
            }
        }
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        micContainerView.layer.cornerRadius = micContainerView.bounds.width / 2
        micContainerView.clipsToBounds = true
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


    // MARK: - UI SETUP
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


    // CANCEL BUTTON
    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }


    //  START SPEECH → GO TO COUNTDOWN
    @IBAction func beginSpeechTapped(_ sender: UIButton) {

        guard let countdownVC = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        countdownVC.mode = .speech
        navigationController?.pushViewController(countdownVC, animated: true)
    }
}


//  TIMER MANAGER DELEGATE
extension StartJamViewController: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {
        timerLabel.text = "02:00"
    }

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime
    }

    func timerManagerDidFinish() {
        timerLabel.text = "00:00"
    }
    
    func timerDidFinish() {

        SessionProgressManager.shared.markCompleted(.twoMinJam)

        navigationController?.popViewController(animated: true)
    }

}
