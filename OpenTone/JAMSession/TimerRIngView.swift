import UIKit

class TimerRingView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let ringWidth: CGFloat = 22
    private var didSetup = false

    override func layoutSubviews() {
        super.layoutSubviews()

        if !didSetup && bounds.width > 0 && bounds.height > 0 {
            didSetup = true
            setupRing()
        }
    }

    private func setupRing() {

        if backgroundLayer.superlayer == nil {
            layer.addSublayer(backgroundLayer)
        }
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - ringWidth / 2

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor(
            red: 0.90, green: 0.80, blue: 1.0, alpha: 1
        ).cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = ringWidth
        backgroundLayer.lineCap = .round

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(
            red: 86/255,
            green: 61/255,
            blue: 189/255,
            alpha: 1
        ).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = ringWidth
        progressLayer.lineCap = .round
    }

    // REQUIRED for existing ProgressCell and other callers
    func setProgress(value: CGFloat, max: CGFloat) {
        progressLayer.strokeEnd = value / max
    }

    func resetRing() {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 1.0
    }

    func animateRing(remainingSeconds: Int, totalSeconds: Int = 30) {

        if progressLayer.path == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
                self?.animateRing(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: totalSeconds
                )
            }
            return
        }

        progressLayer.removeAllAnimations()

        let startProgress = CGFloat(remainingSeconds) / CGFloat(totalSeconds)
        progressLayer.strokeEnd = startProgress

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = startProgress
        animation.toValue = 0
        animation.duration = TimeInterval(remainingSeconds)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayer.add(animation, forKey: "ringAnimation")
    }
}
