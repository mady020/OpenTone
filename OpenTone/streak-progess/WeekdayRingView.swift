//
//  WeekdayRingView.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

import UIKit

class WeekdayRingView: UIView {
    
    private var isConfigured = false
    private let bgLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isConfigured {
            setup()
            isConfigured = true
        }
    }

    private func setup() {
        layer.sublayers?.removeAll()

        let radius = bounds.width / 2 - 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        bgLayer.path = path.cgPath
        bgLayer.strokeColor = UIColor.systemGray4.cgColor
        bgLayer.lineWidth = 4
        bgLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.systemPurple.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(bgLayer)
        layer.addSublayer(progressLayer)
    }

    func animate(progress: CGFloat) {

        let safeProgress = min(max(progress, 0), 1)

        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 0

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = safeProgress
        animation.duration = 0.6
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayer.add(animation, forKey: "weekdayProgress")
    }
    
    func setProgress(_ progress: CGFloat) {

        let safeProgress = min(max(progress, 0), 1)   // safety

        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = safeProgress
    }

}
