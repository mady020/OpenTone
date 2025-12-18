import UIKit

class WeekdayRingView: UIView {
    
    // Properties
    var onTap: (() -> Void)?
    private var isConfigured = false
    
    private let bgLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    // Custom Purple Color
    private let brandPurple = UIColor(red: 0.42, green: 0.05, blue: 0.68, alpha: 1).cgColor

    // Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isConfigured {
            setupLayers()
            setupGesture()
            isConfigured = true
        }
    }

    // Setup
    private func setupLayers() {
        layer.sublayers?.removeAll()

        let radius = bounds.width / 2 - 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        ).cgPath

        // 1. Background Gray Ring
        bgLayer.path = circularPath
        bgLayer.strokeColor = UIColor.systemGray4.cgColor
        bgLayer.lineWidth = 4
        bgLayer.fillColor = UIColor.clear.cgColor

        // 2. Progress Ring
        progressLayer.path = circularPath
        progressLayer.strokeColor = brandPurple
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(bgLayer)
        layer.addSublayer(progressLayer)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // Animation & Updates
    
    /// Animates the progress from 0 to target value
    func animate(progress: CGFloat, yesterdayProgress: CGFloat = 0) {
        let safeProgress = min(max(progress, 0), 1)
        progressLayer.removeAllAnimations()

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = safeProgress
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        progressLayer.add(animation, forKey: "todayProgress")
    }

    /// Sets progress immediately without animation
    func setProgress(_ progress: CGFloat) {
        progressLayer.strokeEnd = min(max(progress, 0), 1)
    }

    /// Updates the visual scale and stroke thickness when a day is selected or is 'Today'
    func setEmphasis(isToday: Bool = false, isSelected: Bool = false) {
        let isActive = isToday || isSelected
        let scale: CGFloat = isActive ? 1.12 : 1.0
        let lineWidth: CGFloat = isActive ? 5 : 4

        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        bgLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth

        bgLayer.strokeColor = isActive
            ? UIColor.systemPurple.withAlphaComponent(0.2).cgColor
            : UIColor.systemGray4.cgColor
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

