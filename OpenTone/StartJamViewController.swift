//
//  StartJamViewController.swift
//  OpenTone
//
//  Created by Student on 03/12/25.
//
//
//  StartJamViewController.swift
//  OpenTone
//

import UIKit

class StartJamViewController: UIViewController {

    @IBOutlet weak var timerRingView: TimerRingView!
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var countdownLabel: UILabel!

    @IBOutlet weak var waveView: UIView!

    // dynamic topic label (make sure this outlet is connected)
    @IBOutlet weak var topicTitleLabel: UILabel!

    @IBOutlet weak var bulbButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var topicText: String = ""   // set by PrepareJam before push

    private let timerManager = TimerManager()
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()
        timerManager.delegate = self
        setupInitialUI()
        setupWaveAnimation()
    }

    // assign topic here so outlet gets the value
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topicTitleLabel.text = topicText
        topicTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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

    private func setupInitialUI() {
        timerLabel.text = "02:00"
        timerLabel.isHidden = true
        countdownLabel.text = ""
        countdownLabel.alpha = 0
        countdownLabel.isHidden = true
    }

    private func setupWaveAnimation() {
        waveView.subviews.forEach { $0.removeFromSuperview() }
        let wave = UIView(frame: CGRect(x: 0, y: waveView.bounds.midY - 1, width: waveView.bounds.width, height: 2))
        wave.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        wave.backgroundColor = UIColor(red: 143/255, green: 120/255, blue: 234/255, alpha: 0.6)
        waveView.addSubview(wave)
        UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse], animations: {
            wave.transform = CGAffineTransform(scaleX: 1, y: 5)
        }, completion: nil)
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

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
    }

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime
    }

    func timerManagerDidFinish() {
        timerLabel.text = "00:00"
        // future: move to result screen
    }
}
