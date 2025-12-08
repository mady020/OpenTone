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

    // BOTTOM SHEET
    @IBOutlet weak var bottomSheetView: UIView!
    
    
    
    @IBOutlet weak var collapsedControlsView: UIStackView!
    @IBOutlet weak var pauseMenuView: UIStackView!

    // MARK: - VARIABLES

    var topicText: String = ""

    private let timerManager = TimerManager()
    private var didStart = false

    // Bottom Sheet Control
    private var isSheetExpanded = false
    private let collapsedHeight: CGFloat = 120
    private let expandedHeight: CGFloat = 320


    // MARK: - VIEW LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        timerManager.delegate = self
        setupInitialUI()
        setupWaveAnimation()
        setupBottomSheet()

        // Mic toggle gesture
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


    // MARK: - MIC UI

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


    // MARK: - INITIAL UI

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


    // MARK: - BOTTOM SHEET SETUP

    func setupBottomSheet() {

        bottomSheetBottomConstraint.constant = 0
        pauseMenuView.isHidden = true

        bottomSheetView.layer.cornerRadius = 22
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomSheetView.clipsToBounds = true

        // Add pan gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        bottomSheetView.addGestureRecognizer(pan)
    }


    // MARK: - SHEET DRAG BEHAVIOR

    @objc func handleSheetPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {

        case .changed:
            if translation.y < 0 { // dragging upward
                bottomSheetBottomConstraint.constant =
                    max(translation.y, -(expandedHeight - collapsedHeight))
            }

        case .ended:
            if translation.y < -40 {
                expandSheet()
            } else {
                collapseSheet()
            }

        default:
            break
        }
    }


    func expandSheet() {
        isSheetExpanded = true

        bottomSheetBottomConstraint.constant = -(expandedHeight - collapsedHeight)

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4,
                       options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }

        collapsedControlsView.isHidden = true
        pauseMenuView.isHidden = false
    }


    func collapseSheet() {
        isSheetExpanded = false

        bottomSheetBottomConstraint.constant = 0

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4,
                       options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }

        collapsedControlsView.isHidden = false
        pauseMenuView.isHidden = true
    }


    // MARK: - BUTTON ACTIONS

    @IBAction func cancelTapped(_ sender: UIButton) {
        expandSheet()  // pressing X opens the pause menu
    }


    @IBAction func beginSpeechTapped(_ sender: UIButton) {
        guard let countdownVC = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        countdownVC.mode = .speech
        navigationController?.pushViewController(countdownVC, animated: true)
    }
}


// MARK: - TIMER DELEGATE

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
}
