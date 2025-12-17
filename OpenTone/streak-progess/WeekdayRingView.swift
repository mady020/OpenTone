//
//  WeekdayRingView.swift
//  OpenTone
//

import UIKit

class WeekdayRingView: UIView {
    var onTap: (() -> Void)?
    private var isConfigured = false
    
    private let bgLayer = CAShapeLayer()
    private let yesterdayLayer = CAShapeLayer() // NEW layer
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

        // Background ring
        bgLayer.path = path.cgPath
        bgLayer.strokeColor = UIColor.systemGray4.cgColor
        bgLayer.lineWidth = 4
        bgLayer.fillColor = UIColor.clear.cgColor

        // Yesterday progress (cool purple inside)
        yesterdayLayer.path = path.cgPath
        yesterdayLayer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.5).cgColor
        yesterdayLayer.lineWidth = 2.5
        yesterdayLayer.fillColor = UIColor.clear.cgColor
        yesterdayLayer.strokeEnd = 0

        // Today/main progress
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.systemPurple.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(bgLayer)
        layer.addSublayer(yesterdayLayer)
        layer.addSublayer(progressLayer)

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    /// Animate today + yesterday progress
    func animate(progress: CGFloat, yesterdayProgress: CGFloat = 0) {
        let safeProgress = min(max(progress, 0), 1)
        let safeYesterday = min(max(yesterdayProgress, 0), 1)

        progressLayer.removeAllAnimations()
        yesterdayLayer.removeAllAnimations()

        // Today animation
        let todayAnim = CABasicAnimation(keyPath: "strokeEnd")
        todayAnim.fromValue = 0
        todayAnim.toValue = safeProgress
        todayAnim.duration = 0.6
        todayAnim.fillMode = .forwards
        todayAnim.isRemovedOnCompletion = false
        progressLayer.add(todayAnim, forKey: "todayProgress")

        // Yesterday animation
        let yesterdayAnim = CABasicAnimation(keyPath: "strokeEnd")
        yesterdayAnim.fromValue = 0
        yesterdayAnim.toValue = safeYesterday
        yesterdayAnim.duration = 0.6
        yesterdayAnim.fillMode = .forwards
        yesterdayAnim.isRemovedOnCompletion = false
        yesterdayLayer.add(yesterdayAnim, forKey: "yesterdayProgress")
    }

    func setProgress(_ progress: CGFloat, yesterdayProgress: CGFloat = 0) {
        let safeProgress = min(max(progress, 0), 1)
        let safeYesterday = min(max(yesterdayProgress, 0), 1)

        progressLayer.strokeEnd = safeProgress
        yesterdayLayer.strokeEnd = safeYesterday
    }

    func setEmphasis(isToday: Bool = false, isSelected: Bool = false) {
        let scale: CGFloat = (isToday || isSelected) ? 1.12 : 1.0
        let lineWidth: CGFloat = (isToday || isSelected) ? 5 : 4

        transform = CGAffineTransform(scaleX: scale, y: scale)

        bgLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth

        // Color logic
        if isToday {
            progressLayer.strokeColor = UIColor.systemPurple.cgColor
            bgLayer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.2).cgColor
        } else {
            progressLayer.strokeColor = UIColor.systemGray3.cgColor
            bgLayer.strokeColor = UIColor.systemGray4.cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}












//
//  WeekdayRingView.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

//
//  WeekdayRingView.swift
//  OpenTone
//
//  Created by Student on 10/12/25.
//

//import UIKit
//
//class WeekdayRingView: UIView {
//    var onTap: (() -> Void)?
//    private var isConfigured = false
//    private let bgLayer = CAShapeLayer()
//    private let progressLayer = CAShapeLayer()
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        if !isConfigured {
//            setup()
//            isConfigured = true
//        }
//    }
//
//    private func setup() {
//        layer.sublayers?.removeAll()
//
//        let radius = bounds.width / 2 - 2
//        let center = CGPoint(x: bounds.midX, y: bounds.midY)
//
//        let path = UIBezierPath(
//            arcCenter: center,
//            radius: radius,
//            startAngle: -.pi / 2,
//            endAngle: 1.5 * .pi,
//            clockwise: true
//        )
//
//        bgLayer.path = path.cgPath
//        bgLayer.strokeColor = UIColor.systemGray4.cgColor
//        bgLayer.lineWidth = 4
//        bgLayer.fillColor = UIColor.clear.cgColor
//
//        progressLayer.path = path.cgPath
//        progressLayer.strokeColor = UIColor.systemPurple.cgColor
//        progressLayer.lineWidth = 4
//        progressLayer.lineCap = .round
//        progressLayer.fillColor = UIColor.clear.cgColor
//        progressLayer.strokeEnd = 0
//
//        layer.addSublayer(bgLayer)
//        layer.addSublayer(progressLayer)
//        
//        let tapGesture = UITapGestureRecognizer(
//            target: self,
//            action: #selector(handleTap)
//        )
//        addGestureRecognizer(tapGesture)
//        isUserInteractionEnabled = true
//
//    }
//
//    func animate(progress: CGFloat) {
//
//        let safeProgress = min(max(progress, 0), 1)
//
//        progressLayer.removeAllAnimations()
//        progressLayer.strokeEnd = 0
//
//        let animation = CABasicAnimation(keyPath: "strokeEnd")
//        animation.fromValue = 0
//        animation.toValue = safeProgress
//        animation.duration = 0.6
//        animation.fillMode = .forwards
//        animation.isRemovedOnCompletion = false
//
//        progressLayer.add(animation, forKey: "weekdayProgress")
//    }
//    
//    func setProgress(_ progress: CGFloat) {
//
//        let safeProgress = min(max(progress, 0), 1)   // safety
//
//        progressLayer.removeAllAnimations()
//        progressLayer.strokeEnd = safeProgress
//    }
//    func setEmphasis(isToday: Bool = false, isSelected: Bool = false) {
//
//        let scale: CGFloat = (isToday || isSelected) ? 1.12 : 1.0
//        let lineWidth: CGFloat = (isToday || isSelected) ? 5 : 4
//
//        transform = CGAffineTransform(scaleX: scale, y: scale)
//
//        bgLayer.lineWidth = lineWidth
//        progressLayer.lineWidth = lineWidth
//
//        // Color logic
//        if isToday {
//            progressLayer.strokeColor = UIColor.systemPurple.cgColor
//            bgLayer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.2).cgColor
//        } else {
//            progressLayer.strokeColor = UIColor.systemGray3.cgColor
//            bgLayer.strokeColor = UIColor.systemGray4.cgColor
//        }
//        
//    }
//
//    @objc private func handleTap() {
//        onTap?()
//    }
//

