////
////  TopicCell.swift
////  OpenTone
////
////  Created by Student on 29/11/25.
////
//

//
//  TimerCell.swift
//  OpenTone
//
//

import UIKit

final class TimerCell: UICollectionViewCell {

    static let reuseId = "TimerCell"

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!

    private var sequenceTimer: Timer?
    private var mainTimer: Timer?

    private var didStartRing = false

    private let totalSeconds = 120
    private var secondsLeft = 120
    private let startSequence = ["3", "2", "1", "Start"]

    override func awakeFromNib() {
        super.awakeFromNib()
        print("TimerCell LOADED → countdownLabel:", countdownLabel as Any)
        resetUI()
 
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        invalidateTimers()
        didStartRing = false

        timerRingView.resetRing()
        resetUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // START ANIMATION + COUNTDOWN ONLY WHEN VIEW IS READY
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.didStartRing,
               self.timerRingView.bounds.width > 20 {

                self.didStartRing = true

                // reset + animate ring
                self.timerRingView.resetRing()
                self.timerRingView.animateRing(duration: 120)

                // start 3-2-1 + numeric timer
//                self.startCountdownSequence()
            }
        }
    }

    // MARK: - UI Reset
    private func resetUI() {
        secondsLeft = totalSeconds
        timerLabel.text = format(secondsLeft)
        timerLabel.isHidden = true

        countdownLabel.alpha = 0.5
        countdownLabel.isHidden = true
    }

    // MARK: - 3,2,1 Sequence
    
    private func startCountdownSequence() {
        
//        countdownLabel.isHidden = false
//        timerLabel.isHidden = true

        var index = 0

        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                             repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }

            if index >= self.startSequence.count {
                t.invalidate()

                self.countdownLabel.isHidden = true
                self.timerLabel.isHidden = false

                self.startMainTimer()
                return
            }

            self.showCountdown(text: self.startSequence[index])
            index += 1
        }
    }

    private func showCountdown(text: String) {
        countdownLabel.text = text
        countdownLabel.alpha = 0
        countdownLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

        UIView.animate(withDuration: 0.45, animations: {
            self.countdownLabel.alpha = 1
            self.countdownLabel.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.countdownLabel.alpha = 0
            }
        })
    }

    // MARK: - Main Timer
    private func startMainTimer() {
        secondsLeft = totalSeconds

        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true) { [weak self] t in
            guard let self = self else { return }

            self.secondsLeft -= 1

            if self.secondsLeft <= 0 {
                t.invalidate()
                self.timerLabel.text = "00:00"
            } else {
                self.timerLabel.text = self.format(self.secondsLeft)
            }
        }
    }

    // MARK: - Helpers
    private func invalidateTimers() {
        sequenceTimer?.invalidate()
        sequenceTimer = nil

        mainTimer?.invalidate()
        mainTimer = nil
    }

    private func format(_ seconds: Int) -> String {
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
