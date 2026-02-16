import UIKit

class WeekdayRingView: UIView {
    var onTap: (() -> Void)?
    private var isConfigured = false

    private let bgLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isConfigured {
            setupLayers()
            setupGesture()
            isConfigured = true
        }
    }

    private func setupLayers() {
        layer.sublayers?.removeAll()

        let radius = bounds.width / 2 - 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circularPath = UIBezierPath(
            arcCenter: center, radius: radius,
            startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true
        ).cgPath

        bgLayer.path = circularPath
        bgLayer.strokeColor = AppColors.ringTrack.cgColor
        bgLayer.lineWidth = 4
        bgLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = circularPath
        progressLayer.strokeColor = AppColors.primary.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(bgLayer)
        layer.addSublayer(progressLayer)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: WeekdayRingView, _) in
            self.bgLayer.strokeColor = AppColors.ringTrack.cgColor
            self.progressLayer.strokeColor = AppColors.primary.cgColor
        }
    }

    func animate(progress: CGFloat, yesterdayProgress: CGFloat = 0) {
        let safeProgress = min(max(progress, 0), 1)
        progressLayer.removeAllAnimations()

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = safeProgress
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "todayProgress")
    }

    func setProgress(_ progress: CGFloat) {
        progressLayer.strokeEnd = min(max(progress, 0), 1)
    }

    func setEmphasis(isToday: Bool = false, isSelected: Bool = false) {
        let isActive = isToday || isSelected
        let scale: CGFloat = isActive ? 1.12 : 1.0
        let lineWidth: CGFloat = isActive ? 5 : 4

        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        bgLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth

        bgLayer.strokeColor = isActive
            ? AppColors.primary.withAlphaComponent(0.2).cgColor
            : AppColors.ringTrack.cgColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
