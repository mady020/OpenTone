import UIKit

class CircularProgressView: UIView {

    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()

    // Configure colors
    public var trackColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3) {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    public var progressColor: UIColor = UIColor.purple {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    // Set progress (0.0 to 1.0)
    private var progress: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        createCircularPath()
    }

    private func createCircularPath() {
        let radius = min(bounds.width, bounds.height) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius - 3,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        // Track layer
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = 4
        trackLayer.lineCap = .round

        // Progress layer
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 4
        progressLayer.strokeEnd = progress
        progressLayer.lineCap = .round

        layer.sublayers?.removeAll()
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }

    // Animate progress
    public func setProgress(_ newValue: CGFloat, animated: Bool = true) {
        progress = max(0, min(1, newValue))

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = progress
            animation.duration = 0.4
            progressLayer.strokeEnd = progress
            progressLayer.add(animation, forKey: "progressAnim")
        } else {
            progressLayer.strokeEnd = progress
        }
    }
}
