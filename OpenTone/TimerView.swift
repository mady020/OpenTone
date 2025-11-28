////
////  TimerView.swift
////  OpenTone
////
////  Created by Student on 27/11/25.
////
//
//import Foundation
////
//// TimerView.swift
//// Reusable circular timer view with ready-set-go sequence
//
//import UIKit
//
//final class TimerView: UIView {
//
//    // MARK: - Public
//    var totalSeconds: Int = 120 {
//        didSet { reset() }
//    }
//
//    var onTimerStarted: (() -> Void)?
//    var onTimerFinished: (() -> Void)?
//
//    // MARK: - UI
//    private let backgroundRing = CAShapeLayer()
//    private let progressRing = CAShapeLayer()
//
//    private let timeLabel: UILabel = {
//        let l = UILabel()
//        l.font = .boldSystemFont(ofSize: 32)
//        l.textAlignment = .center
//        l.textColor = .label
//        l.translatesAutoresizingMaskIntoConstraints = false
//        return l
//    }()
//
//    private let bigCountdownLabel: UILabel = {
//        let l = UILabel()
//        l.font = .boldSystemFont(ofSize: 78)
//        l.textAlignment = .center
//        l.textColor = .label
//        l.alpha = 0
//        l.translatesAutoresizingMaskIntoConstraints = false
//        return l
//    }()
//
//    // MARK: - Config
//    private let ringLineWidth: CGFloat = 22
//    private var timer: Timer?
//    private var remainingSeconds = 0
//    private var didSetPath = false
//
//    // MARK: - Init
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setup()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setup()
//    }
//
//    private func setup() {
//        backgroundColor = .clear
//        layer.addSublayer(backgroundRing)
//        layer.addSublayer(progressRing)
//
//        addSubview(timeLabel)
//        addSubview(bigCountdownLabel)
//
//        NSLayoutConstraint.activate([
//            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
//            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
//
//            bigCountdownLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
//            bigCountdownLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
//        ])
//
//        reset()
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        guard !didSetPath else { return }
//        didSetPath = true
//
//        let center = CGPoint(x: bounds.midX, y: bounds.midY)
//        let radius = min(bounds.width, bounds.height)/2 - ringLineWidth/2
//
//        let start = -CGFloat.pi/2
//        let end = start + 2*CGFloat.pi
//
//        let path = UIBezierPath(
//            arcCenter: center,
//            radius: radius,
//            startAngle: start,
//            endAngle: end,
//            clockwise: true
//        ).cgPath
//
//        backgroundRing.path = path
//        backgroundRing.lineWidth = ringLineWidth
//        backgroundRing.fillColor = UIColor.clear.cgColor
//        backgroundRing.strokeColor = UIColor(hex: "#F2EEFF").cgColor
//
//        progressRing.path = path
//        progressRing.lineWidth = ringLineWidth
//        progressRing.fillColor = UIColor.clear.cgColor
//        progressRing.strokeColor = UIColor(hex: "#8F78EA").cgColor
//        progressRing.lineCap = .round
//        progressRing.strokeEnd = 1
//    }
//
//    // MARK: - API
//    func reset() {
//        timer?.invalidate()
//        timer = nil
//
//        remainingSeconds = totalSeconds
//        timeLabel.text = format(remainingSeconds)
//
//        progressRing.strokeEnd = 1
//        timeLabel.alpha = 1
//        backgroundRing.opacity = 1
//        progressRing.opacity = 1
//        bigCountdownLabel.alpha = 0
//    }
//
//    func runReadySequenceThenStart() {
//        reset()
//        hideRing()
//
//        let seq = ["3", "2", "1", "Start"]
//        runSequence(seq) { [weak self] in
//            guard let self = self else { return }
//            self.showRing()
//            self.startTimer()
//            self.onTimerStarted?()
//        }
//    }
//
//    func stop() {
//        timer?.invalidate()
//        timer = nil
//    }
//
//    // MARK: - Private helpers
//    private func hideRing() {
//        timeLabel.alpha = 0
//        backgroundRing.opacity = 0
//        progressRing.opacity = 0
//    }
//
//    private func showRing() {
//        UIView.animate(withDuration: 0.25) {
//            self.timeLabel.alpha = 1
//            self.backgroundRing.opacity = 1
//            self.progressRing.opacity = 1
//        }
//    }
//
//    private func format(_ sec: Int) -> String {
//        return String(format: "%02d:%02d", sec/60, sec%60)
//    }
//
//    private func runSequence(_ items: [String], completion: @escaping () -> Void) {
//        var index = 0
//
//        func showNext() {
//            if index >= items.count {
//                completion()
//                return
//            }
//
//            let text = items[index]
//            index += 1
//
//            bigCountdownLabel.text = text
//            bigCountdownLabel.alpha = 0
//            bigCountdownLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
//
//            UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: [], animations: {
//                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
//                    self.bigCountdownLabel.alpha = 1
//                    self.bigCountdownLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//                }
//                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
//                    self.bigCountdownLabel.alpha = 0
//                    self.bigCountdownLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//                }
//            }) { _ in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                    showNext()
//                }
//            }
//        }
//
//        showNext()
//    }
//
//    private func startTimer() {
//        remainingSeconds = totalSeconds
//        timeLabel.text = format(remainingSeconds)
//
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
//            guard let self = self else { return }
//
//            self.remainingSeconds -= 1
//            if self.remainingSeconds <= 0 {
//                t.invalidate()
//                self.timeLabel.text = "00:00"
//                self.animateRing(to: 0)
//                self.onTimerFinished?()
//            } else {
//                self.timeLabel.text = self.format(self.remainingSeconds)
//                let remainingRatio = CGFloat(self.remainingSeconds)/CGFloat(self.totalSeconds)
//                self.animateRing(to: remainingRatio)
//            }
//        }
//    }
//
//    private func animateRing(to value: CGFloat) {
//        let anim = CABasicAnimation(keyPath: "strokeEnd")
//        anim.fromValue = progressRing.presentation()?.strokeEnd ?? progressRing.strokeEnd
//        anim.toValue = value
//        anim.duration = 0.35
//        anim.fillMode = .forwards
//        anim.isRemovedOnCompletion = false
//        progressRing.strokeEnd = value
//        progressRing.add(anim, forKey: "strokeEnd")
//    }
//}
//
//extension UIColor {
//    convenience init(hex: String) {
//        let hex = hex.replacingOccurrences(of: "#", with: "")
//        var int = UInt64()
//        Scanner(string: hex).scanHexInt64(&int)
//
//        let r = CGFloat((int >> 16) & 0xFF) / 255
//        let g = CGFloat((int >> 8) & 0xFF) / 255
//        let b = CGFloat(int & 0xFF) / 255
//
//        self.init(red: r, green: g, blue: b, alpha: 1)
//    }
//}
