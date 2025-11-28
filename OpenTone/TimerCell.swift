//
//  TimerCell.swift
//  OpenTone
//
//  Created by Student on 27/11/25.
//

import UIKit

final class TimerCell: UICollectionViewCell {

    static let reuseId = "TimerCell"

    // MARK: - Outlets
    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!

    // MARK: - Timers
    private var sequenceTimer: Timer?
    private var mainTimer: Timer?
    private var ringDidLoad = false

    override func layoutSubviews() {
        super.layoutSubviews()

        // Run only once after storyboard loads the views
        if !ringDidLoad {
            ringDidLoad = true
            
        }
    }


    // Countdown sequence
    private let startSequence = ["3", "2", "1", "Start"]
    private var currentIndex = 0

    // Total timer seconds (2 minutes)
    private var totalSeconds = 120
    private var secondsLeft = 120

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        resetUI()

        // Optional debug logging
        print("TIMER CELL LOADED ---")
        print("timerRingView =", timerRingView as Any)
        print("timerLabel =", timerLabel as Any)
        print("countdownLabel =", countdownLabel as Any)

        // Start automatically after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startCountdownAndTimer()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        invalidateAllTimers()
        resetUI()
    }

    // MARK: - UI Reset
    private func resetUI() {
        secondsLeft = totalSeconds
        timerLabel.text = formatted(seconds: secondsLeft)
        timerLabel.isHidden = true

        countdownLabel.isHidden = true
        countdownLabel.alpha = 0
        countdownLabel.transform = .identity

       
    }

    // MARK: - Start Everything
    func startCountdownAndTimer() {
        invalidateAllTimers()
        currentIndex = 0
        runStartSequence()
    }

    // MARK: - 3 → 2 → 1 → Start (NON-recursive)
    private func runStartSequence() {
        countdownLabel.isHidden = false
        timerLabel.isHidden = true

        let interval: TimeInterval = 0.9

        sequenceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            if self.currentIndex >= self.startSequence.count {
                timer.invalidate()

                DispatchQueue.main.async {
                    self.countdownLabel.isHidden = true
                    self.timerLabel.isHidden = false

                    // Start ring animation
                  

                    // Start numeric countdown
                    self.startMainTimer()
                }
                return
            }

            let text = self.startSequence[self.currentIndex]
            self.showCountdown(text: text)

            self.currentIndex += 1
        }
    }

    private func showCountdown(text: String) {
        DispatchQueue.main.async {
            self.countdownLabel.text = text
            self.countdownLabel.alpha = 0
            self.countdownLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

            UIView.animate(withDuration: 0.5, animations: {
                self.countdownLabel.alpha = 1
                self.countdownLabel.transform = .identity
            }, completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    self.countdownLabel.alpha = 0
                }
            })
        }
    }

    // MARK: - Main 120s Timer
    private func startMainTimer() {
        invalidateMainTimer()
        secondsLeft = totalSeconds

        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }

            self.secondsLeft -= 1

            DispatchQueue.main.async {
                if self.secondsLeft <= 0 {
                    t.invalidate()
                    self.timerLabel.text = "00:00"
                } else {
                    self.timerLabel.text = self.formatted(seconds: self.secondsLeft)
                }
            }
        }
    }

    // MARK: - Helpers
    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func invalidateSequenceTimer() {
        sequenceTimer?.invalidate()
        sequenceTimer = nil
    }

    private func invalidateMainTimer() {
        mainTimer?.invalidate()
        mainTimer = nil
    }

    private func invalidateAllTimers() {
        invalidateSequenceTimer()
        invalidateMainTimer()
    }
}
