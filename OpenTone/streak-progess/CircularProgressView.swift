import UIKit

class CircularProgressView: UIView {

    private let ringLayer = CAShapeLayer()
    private var isSetupDone = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isSetupDone {
            setupRing()
            isSetupDone = true
        }
    }

    private func setupRing() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 3

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        ringLayer.path = path.cgPath
        ringLayer.strokeColor = UIColor.systemPurple.cgColor
        ringLayer.lineWidth = 4
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeEnd = 0

        layer.addSublayer(ringLayer)
    }

    func animate(progress: CGFloat) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = progress
        animation.duration = 0.6
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        ringLayer.add(animation, forKey: "smallRingAnimation")
    }
}
