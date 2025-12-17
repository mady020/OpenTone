//
//  BigCircularProgressView.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

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

        // Remove only shape layers (SAFE)
        layer.sublayers?.forEach {
            if $0 is CAShapeLayer {
                $0.removeFromSuperlayer()
            }
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.lineWidth = 10
        backgroundLayer.fillColor = UIColor.clear.cgColor

        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.systemPurple.cgColor
        progressLayer.lineWidth = 10
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
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

