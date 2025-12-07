import UIKit

class BigCircularProgressView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    // Value between 0.0 → 1.0
    var progress: CGFloat = 0 {
        didSet {
            updateProgress(animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCircularPath()
    }

    //Setup Layers
    private func setupLayers() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        trackLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor

        trackLayer.lineCap = .round
        progressLayer.lineCap = .round

        trackLayer.lineWidth = 14
        progressLayer.lineWidth = 14

        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        progressLayer.strokeColor = UIColor.systemPurple.cgColor

        progressLayer.strokeEnd = 0
    }

    // Path
    private func layoutCircularPath() {
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2.2

        let circularPath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        )

        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    // Progress Update
    private func updateProgress(animated: Bool) {
        let clampedProgress = max(0, min(progress, 1))

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.8
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            progressLayer.add(animation, forKey: "progressAnimation")
        }

        progressLayer.strokeEnd = clampedProgress
    }
}
