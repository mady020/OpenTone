//
//  TimerRingView.swift
//  OpenTone
//
//  Created by Student on 27/11/25.

import UIKit

class TimerRingView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let ringWidth: CGFloat = 18

    var totalTime: CGFloat = 120
    var remainingTime: CGFloat = 120 {
        didSet { updateProgress() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupRing()
    }

    private func setupRing() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - ringWidth/2

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -.pi/2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        // Light background ring
        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor(
            red: 242/255, green: 238/255, blue: 255/255, alpha: 1
        ).cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = ringWidth
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)

        // Purple progress ring
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(
            red: 143/255, green: 120/255, blue: 234/255, alpha: 1
        ).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = ringWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1
        layer.addSublayer(progressLayer)
    }

    private func updateProgress() {
        let progress = remainingTime / totalTime
        progressLayer.strokeEnd = progress
    }

    func animateRing(duration: TimeInterval) {
        remainingTime = totalTime
        progressLayer.removeAllAnimations()

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 1
        anim.toValue = 0
        anim.duration = duration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        progressLayer.add(anim, forKey: "ring")
    }

    // New: reset helper used by TimerCell
    func resetRing() {
        progressLayer.removeAllAnimations()
        remainingTime = totalTime
        progressLayer.strokeEnd = 1
        // If layout hasn’t happened yet, ensure layers exist
        if layer.sublayers == nil || layer.sublayers?.isEmpty == true {
            setupRing()
        }
    }
}
