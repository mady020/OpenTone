//
//  TimerRingView.swift
//  OpenTone
//
//  Created by Student on 27/11/25.

import UIKit

class TimerRingView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let ringWidth: CGFloat = 22
    private var didSetup = false

    override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure setup only once AND when size is valid
        if !didSetup && bounds.width > 0 && bounds.height > 0 {
            didSetup = true
            setupRing()
        }
    }

    private func setupRing() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - ringWidth / 2

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        // Background ring
        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor(
            red: 242/255, green: 238/255, blue: 255/255, alpha: 1
        ).cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = ringWidth
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)

        // Progress ring
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(
            red: 143/255, green: 120/255, blue: 234/255, alpha: 1
        ).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = ringWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1.0
        layer.addSublayer(progressLayer)
    }

    // Reset to full ring
    func resetRing() {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 1.0
    }

    // Safe animation function
    func animateRing(duration: TimeInterval) {
        layoutIfNeeded()

        // If path isn't ready yet, retry slightly later
        if progressLayer.path == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
                self?.animateRing(duration: duration)
            }
            return
        }

        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 1.0

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayer.add(animation, forKey: "ringAnimation")
    }
}
