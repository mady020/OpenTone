
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

    private let timerManager = TimerManager(totalSeconds: 30)
    private var didConfigure = false
    private var currentSeconds = 30

    override func awakeFromNib() {
        super.awakeFromNib()
        timerManager.delegate = self
        resetUI()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        timerRingView.backgroundColor = UIColor.clear
        timerRingView.superview?.backgroundColor = UIColor.clear
        timerLabel.textColor = UIColor.label
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

        currentSeconds = reset ? 30 : secondsLeft

        timerRingView.resetRing()
        timerRingView.animateRing(
            remainingSeconds: currentSeconds,
            totalSeconds: 30
        )

        timerManager.start(from: currentSeconds)
    }

    func pauseTimer() {
        timerManager.pause()
        timerRingView.resetRing() 
        timerRingView.setProgress(value: CGFloat(currentSeconds), max: 30)
    }

    func resumeTimer() {
        timerManager.start(from: currentSeconds)
        timerRingView.animateRing(
            remainingSeconds: currentSeconds,
            totalSeconds: 30
        )
    }


    private func resetUI() {
        timerLabel.text = "00:30"
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

