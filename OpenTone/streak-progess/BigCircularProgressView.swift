import UIKit

class BigCircularProgressView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var isSetupDone = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width == 0 || bounds.height == 0 { return }
        if !isSetupDone {
            setupRing()
            isSetupDone = true
        }
    }

    private func setupRing() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
          let radius = min(bounds.width, bounds.height) / 2 - 14

          let path = UIBezierPath(
              arcCenter: center,
              radius: radius,
              startAngle: -.pi / 2,
              endAngle: 1.5 * .pi,
              clockwise: true
          )

        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.lineWidth = 14
        backgroundLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.systemPurple.cgColor
        progressLayer.lineWidth = 14
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    func animate(progress: CGFloat) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = progress
        animation.duration = 1.2
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "bigRingAnimation")
    }
}
