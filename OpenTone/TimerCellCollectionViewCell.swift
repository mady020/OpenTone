//
//  TimerCellCollectionViewCell.swift
//  OpenTone
//
//  Created by Student on 02/12/25.
//

import UIKit

class TimerCellCollectionViewCell: UICollectionViewCell {
    

        static let reuseId = "TimerCell"

    
    @IBOutlet weak var timerRingView: TimerRingView!
    
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var countdownLabel: UILabel!
    
    
   
    private var sequenceTimer: Timer?
       private var mainTimer: Timer?

       private var didStart = false

       private let totalSeconds = 120
       private var secondsLeft = 120

       private let startSequence = ["3", "2", "1", "Start"]

       override func awakeFromNib() {
           super.awakeFromNib()
           resetUI()

           // Make labels visible
           timerLabel.textColor = .black
           countdownLabel.textColor = .black

           // Ensure labels on top of the ring
           contentView.bringSubviewToFront(timerLabel)
           contentView.bringSubviewToFront(countdownLabel)
       }

       override func prepareForReuse() {
           super.prepareForReuse()

           invalidateTimers()
           didStart = false

           timerRingView.resetRing()
           resetUI()
       }

       override func layoutSubviews() {
           super.layoutSubviews()

           DispatchQueue.main.async { [weak self] in
               guard let self = self else { return }

               if !self.didStart,
                  self.timerRingView.bounds.width > 20 {

                   self.didStart = true

                   // Reset & animate ring
                   self.timerRingView.resetRing()
                   self.timerRingView.animateRing(duration: 120)

                   // Begin countdown sequence
                   self.startCountdownSequence()
               }
           }
       }

       // MARK: - Reset UI

       private func resetUI() {
           secondsLeft = totalSeconds

           timerLabel.text = format(secondsLeft)
           timerLabel.isHidden = true

           countdownLabel.text = ""
           countdownLabel.alpha = 0
           countdownLabel.isHidden = true
       }

       // MARK: - Countdown

       private func startCountdownSequence() {

           countdownLabel.isHidden = false
           timerLabel.isHidden = true

           var index = 0

           sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                                repeats: true) { [weak self] timer in
               guard let self = self else { timer.invalidate(); return }

               if index >= self.startSequence.count {
                   timer.invalidate()

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

       // MARK: - 2 Minute Timer

       private func startMainTimer() {
           secondsLeft = totalSeconds

           mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                            repeats: true) { [weak self] timer in
               guard let self = self else { return }

               self.secondsLeft -= 1

               if self.secondsLeft <= 0 {
                   timer.invalidate()
                   self.timerLabel.text = "00:00"
                   // TODO → Navigate to next screen
               } else {
                   self.timerLabel.text = self.format(self.secondsLeft)
               }
           }
       }

       // MARK: - Helpers

       private func invalidateTimers() {
           sequenceTimer?.invalidate()
           mainTimer?.invalidate()
           sequenceTimer = nil
           mainTimer = nil
       }

       private func format(_ secs: Int) -> String {
           return String(format: "%02d:%02d", secs / 60, secs % 60)
       }
   }
//        private var sequenceTimer: Timer?
//        private var mainTimer: Timer?
//
//        private var didStartRing = false
//
//        private let totalSeconds = 120
//        private var secondsLeft = 120
//        private let startSequence = ["3", "2", "1", "Start"]
//
//        override func awakeFromNib() {
//            super.awakeFromNib()
//            print("TimerCell LOADED → countdownLabel:", countdownLabel as Any)
//            resetUI()
//     
//        }
//
//        override func prepareForReuse() {
//            super.prepareForReuse()
//
//            invalidateTimers()
//            didStartRing = false
//
//            timerRingView.resetRing()
//            resetUI()
//        }
//
//        override func layoutSubviews() {
//            super.layoutSubviews()
//
//            // START ANIMATION + COUNTDOWN ONLY WHEN VIEW IS READY
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//
//                if !self.didStartRing,
//                   self.timerRingView.bounds.width > 20 {
//
//                    self.didStartRing = true
//
//                    // reset + animate ring
//                    self.timerRingView.resetRing()
//                    self.timerRingView.animateRing(duration: 120)
//
//                    // start 3-2-1 + numeric timer
//    //                self.startCountdownSequence()
//                }
//            }
//        }
//
//        // MARK: - UI Reset
//        private func resetUI() {
//            secondsLeft = totalSeconds
//            timerLabel.text = format(secondsLeft)
//            timerLabel.isHidden = true
//
//            countdownLabel.alpha = 0.5
//            countdownLabel.isHidden = true
//        }
//
//        // MARK: - 3,2,1 Sequence
//        
//        private func startCountdownSequence() {
//            
//    //        countdownLabel.isHidden = false
//    //        timerLabel.isHidden = true
//
//            var index = 0
//
//            sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
//                                                 repeats: true) { [weak self] t in
//                guard let self = self else { t.invalidate(); return }
//
//                if index >= self.startSequence.count {
//                    t.invalidate()
//
//                    self.countdownLabel.isHidden = true
//                    self.timerLabel.isHidden = false
//
//                    self.startMainTimer()
//                    return
//                }
//
//                self.showCountdown(text: self.startSequence[index])
//                index += 1
//            }
//        }
//
//        private func showCountdown(text: String) {
//            countdownLabel.text = text
//            countdownLabel.alpha = 0
//            countdownLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
//
//            UIView.animate(withDuration: 0.45, animations: {
//                self.countdownLabel.alpha = 1
//                self.countdownLabel.transform = .identity
//            }, completion: { _ in
//                UIView.animate(withDuration: 0.25) {
//                    self.countdownLabel.alpha = 0
//                }
//            })
//        }
//
//        // MARK: - Main Timer
//        private func startMainTimer() {
//            secondsLeft = totalSeconds
//
//            mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
//                                             repeats: true) { [weak self] t in
//                guard let self = self else { return }
//
//                self.secondsLeft -= 1
//
//                if self.secondsLeft <= 0 {
//                    t.invalidate()
//                    self.timerLabel.text = "00:00"
//                } else {
//                    self.timerLabel.text = self.format(self.secondsLeft)
//                }
//            }
//        }
//
//        // MARK: - Helpers
//        private func invalidateTimers() {
//            sequenceTimer?.invalidate()
//            sequenceTimer = nil
//
//            mainTimer?.invalidate()
//            mainTimer = nil
//        }
//
//        private func format(_ seconds: Int) -> String {
//            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
//        }
//    }
//
//    
//
