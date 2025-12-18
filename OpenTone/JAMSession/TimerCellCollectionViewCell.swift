//
//  TimerCellCollectionViewCell.swift
//  OpenTone
//
//  Created by Student on 02/12/25.
//
import UIKit

protocol TimerCellDelegate: AnyObject {
    func timerDidFinish()
    func timerDidUpdate(secondsLeft: Int)
}

final class TimerCellCollectionViewCell: UICollectionViewCell {

    static let reuseId = "TimerCell"

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!

    weak var delegate: TimerCellDelegate?

    private let timerManager = TimerManager()
    private var didConfigure = false
    private var currentSeconds = 120

    override func awakeFromNib() {
        super.awakeFromNib()
        timerManager.delegate = self
        resetUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timerManager.reset()
        timerRingView.resetRing()
        didConfigure = false
        resetUI()
    }

    func setupTimer(secondsLeft: Int, reset: Bool) {
        guard !didConfigure else { return }
        didConfigure = true

        currentSeconds = reset ? 120 : secondsLeft

        timerRingView.resetRing()
        timerRingView.animateRing(
            remainingSeconds: currentSeconds,
            totalSeconds: 120
        )

        timerManager.start(from: currentSeconds)
    }

    private func resetUI() {
        timerLabel.text = "02:00"
        timerLabel.isHidden = false
    }
}

extension TimerCellCollectionViewCell: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {}

    func timerManagerDidUpdateMainTimer(_ formattedTime: String) {
        timerLabel.text = formattedTime

        let parts = formattedTime.split(separator: ":")
        if parts.count == 2,
           let m = Int(parts[0]),
           let s = Int(parts[1]) {
            currentSeconds = m * 60 + s
            delegate?.timerDidUpdate(secondsLeft: currentSeconds)
        }
    }

    func timerManagerDidFinish() {
        timerLabel.text = "00:00"
        delegate?.timerDidFinish()
    }
}

