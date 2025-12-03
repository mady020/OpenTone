//
//  TimerCellCollectionViewCell.swift
//  OpenTone
//
//  Created by Student on 02/12/25.
//

import UIKit


protocol TimerCellDelegate: AnyObject {
    func timerDidFinish()
}

final class TimerCellCollectionViewCell: UICollectionViewCell {
    

        static let reuseId = "TimerCell"

    
    @IBOutlet weak var timerRingView: TimerRingView!
    
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var countdownLabel: UILabel!
    
    
    weak var delegate: TimerCellDelegate?

       private let timerManager = TimerManager()
       private var didStart = false

       override func awakeFromNib() {
           super.awakeFromNib()

           timerManager.delegate = self
           setupUI()
       }

       override func prepareForReuse() {
           super.prepareForReuse()

           timerManager.reset()
           didStart = false
           timerRingView.resetRing()
           resetUI()
       }

       override func layoutSubviews() {
           super.layoutSubviews()

           DispatchQueue.main.async { [weak self] in
               guard let self = self else { return }

               if !self.didStart, self.timerRingView.bounds.width > 20 {

                   self.didStart = true

                   self.timerRingView.resetRing()
                   self.timerRingView.animateRing(duration: 120)

                   self.timerManager.start()
               }
           }
       }

       private func setupUI() {
           resetUI()
           timerLabel.textColor = .black
           countdownLabel.textColor = .black
           contentView.bringSubviewToFront(timerLabel)
           contentView.bringSubviewToFront(countdownLabel)
       }

       private func resetUI() {
           timerLabel.text = "02:00"
           timerLabel.isHidden = true

           countdownLabel.text = ""
           countdownLabel.alpha = 0
           countdownLabel.isHidden = true
       }

       private func animateCountdown(_ text: String) {
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

       private func format(_ sec: Int) -> String {
           return String(format: "%02d:%02d", sec / 60, sec % 60)
       }
   }

   extension TimerCellCollectionViewCell: TimerManagerDelegate {

       func timerManagerDidUpdateCountdownText(_ text: String) {
           countdownLabel.isHidden = false
           timerLabel.isHidden = true
           animateCountdown(text)
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
           delegate?.timerDidFinish()
       }
   }
