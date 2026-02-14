
import UIKit

class BigCircularProgressView: UIView {

    private var isConfigured = false
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isConfigured {
            setupRing()
            isConfigured = true
        }
    }

    private func setupRing() {
        layer.sublayers?.forEach {
            if $0 is CAShapeLayer { $0.removeFromSuperlayer() }
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10

        let path = UIBezierPath(
            arcCenter: center, radius: radius,
            startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true
        )

        let isDark = traitCollection.userInterfaceStyle == .dark

        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = isDark
            ? UIColor.systemGray5.cgColor
            : UIColor(red: 0.92, green: 0.87, blue: 1.0, alpha: 1).cgColor
        backgroundLayer.lineWidth = 10
        backgroundLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = AppColors.primary.cgColor
        progressLayer.lineWidth = 10
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let isDark = traitCollection.userInterfaceStyle == .dark
            backgroundLayer.strokeColor = isDark
                ? UIColor.systemGray5.cgColor
                : UIColor(red: 0.92, green: 0.87, blue: 1.0, alpha: 1).cgColor
            progressLayer.strokeColor = AppColors.primary.cgColor
        }
    }

    func setProgress(_ progress: CGFloat, animated: Bool = true) {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = progress

        guard animated else { return }

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = progress
        animation.duration = 1.2
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "bigRingAnimation")
    }
}
