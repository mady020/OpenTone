//
//  TimerRingView.swift
//  OpenTone
//
//  Created by Student on 27/11/25.
//

import UIKit

class TimerRingView: UIView {

    private let bgLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let ringWidth: CGFloat = 18

    override func layoutSubviews() {
        super.layoutSubviews()
        setupRing()
    }

    private func setupRing() {
        layer.sublayers?.removeAll()

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - ringWidth/2

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -.pi/2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        // Background ring
        bgLayer.path = path.cgPath
        bgLayer.strokeColor = UIColor(hex: "#F2EEFF").cgColor
        bgLayer.fillColor = UIColor.clear.cgColor
        bgLayer.lineWidth = ringWidth
        bgLayer.lineCap = .round
        layer.addSublayer(bgLayer)

        // Progress ring
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(hex: "#8F78EA").cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = ringWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1
        layer.addSublayer(progressLayer)
    }

    func resetRing() {
        progressLayer.removeAllAnimations()
        progressLayer.strokeEnd = 1
    }

    func animateRing(duration: TimeInterval) {
        resetRing()

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "countdown")
    }
}

// MARK: - Hex Color Helper
extension UIColor {
    convenience init(hex: String) {
        var hex = hex.replacingOccurrences(of: "#", with: "")
        if hex.count == 6 { hex.append("FF") }
        let scanner = Scanner(string: hex)
        var hexValue: UInt64 = 0
        scanner.scanHexInt64(&hexValue)
        let r = CGFloat((hexValue & 0xFF000000) >> 24) / 255
        let g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255
        let b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255
        let a = CGFloat(hexValue & 0x000000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}


//
// The following duplicated implementation was commented out in your file.
// Consider removing it entirely to avoid confusion.
//
//////
//////  TimerRIngView.swift
//////  OpenTone
//////
//////  Created by Student on 27/11/25.
//////
////
////import Foundation
//////
//////  TimerRingView.swift
//////  OpenTone
//////
////
////import UIKit
////
////class TimerRingView: UIView {
////
////    private let backgroundLayer = CAShapeLayer()
////    private let progressLayer = CAShapeLayer()
////
////    private let ringWidth: CGFloat = 18
////
////    var totalTime: CGFloat = 120
////    var remainingTime: CGFloat = 120 {
////        didSet { updateProgress() }
////    }
////
////    override func layoutSubviews() {
////        super.layoutSubviews()
////        setupRing()
////    }
////
////    private func setupRing() {
////        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
////
////        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
////        let radius = min(bounds.width, bounds.height) / 2 - ringWidth/2
////
////        let path = UIBezierPath(
////            arcCenter: centerPoint,
////            radius: radius,
////            startAngle: -.pi/2,
////            endAngle: 1.5 * .pi,
////            clockwise: true
////        )
////
////        // Light background ring
////        backgroundLayer.path = path.cgPath
////        backgroundLayer.strokeColor = UIColor(
////            red: 242/255, green: 238/255, blue: 255/255, alpha: 1
////        ).cgColor
////        backgroundLayer.fillColor = UIColor.clear.cgColor
////        backgroundLayer.lineWidth = ringWidth
////        backgroundLayer.lineCap = .round
////        layer.addSublayer(backgroundLayer)
////
////        // Purple progress ring
////        progressLayer.path = path.cgPath
////        progressLayer.strokeColor = UIColor(
////            red: 143/255, green: 120/255, blue: 234/255, alpha: 1
////        ).cgColor
////        progressLayer.fillColor = UIColor.clear.cgColor
////        progressLayer.lineWidth = ringWidth
////        progressLayer.lineCap = .round
////        progressLayer.strokeEnd = 1
////        layer.addSublayer(progressLayer)
////    }
////
////    private func updateProgress() {
////        let progress = remainingTime / totalTime
////        progressLayer.strokeEnd = progress
////    }
////
////    func animateRing(duration: TimeInterval) {
////        remainingTime = totalTime
////        progressLayer.removeAllAnimations()
////
////        let anim = CABasicAnimation(keyPath: "strokeEnd")
////        anim.fromValue = 1
////        anim.toValue = 0
////        anim.duration = duration
////        anim.fillMode = .forwards
////        anim.isRemovedOnCompletion = false
////        progressLayer.add(anim, forKey: "ring")
////    }
////}
