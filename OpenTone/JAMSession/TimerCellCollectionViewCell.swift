
import UIKit

protocol TimerCellDelegate: AnyObject {
    func timerDidFinish()
}

final class TimerCellCollectionViewCell: UICollectionViewCell {

    static let reuseId = "TimerCell"

    @IBOutlet weak var timerRingView: TimerRingView!
    @IBOutlet weak var timerLabel: UILabel!

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
    }

    private func resetUI() {
        timerLabel.text = "02:00"
        timerLabel.isHidden = false
    }
}

extension TimerCellCollectionViewCell: TimerManagerDelegate {

    func timerManagerDidStartMainTimer() {
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
