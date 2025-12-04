//
//  CountdownViewController.swift
//  OpenTone
//
//  Created by Student on 04/12/25.
//
import UIKit

class CountdownViewController: UIViewController {

    @IBOutlet weak var circleContainer: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!

    private let ringLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()

    private let stepDelay: Double = 1.0  // Timing for 3 → 2 → 1 → Start

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        bottomLabel.text = "Preparation Time"

        setupRing()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startInitialFill()
    }

    // MARK: Create the ring
    private func setupRing() {

        let radius: CGFloat = 130
        let center = CGPoint(x: circleContainer.bounds.midX,
                             y: circleContainer.bounds.midY)

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi/2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        let thickness: CGFloat = 26   // ⬅️ THICKER ring

        // TRACK (light purple)
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(red: 0.90, green: 0.80, blue: 1.0, alpha: 1).cgColor
        trackLayer.lineWidth = thickness
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        circleContainer.layer.addSublayer(trackLayer)

        // ACTIVE RING (dark purple)
        ringLayer.path = path.cgPath
        ringLayer.strokeColor = UIColor(red: 0.42, green: 0.05, blue: 0.68, alpha: 1).cgColor
        ringLayer.lineWidth = thickness
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = .round
        ringLayer.strokeEnd = 0
        circleContainer.layer.addSublayer(ringLayer)
    }

    // MARK: Fill to 100% on first frame
    private func startInitialFill() {

        countdownLabel.text = "3"
        countdownLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        UIView.animate(withDuration: 0.35) {
            self.countdownLabel.transform = .identity
        }

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = 0.4
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        ringLayer.strokeEnd = 1
        ringLayer.add(anim, forKey: "fill")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startCountdown()
        }
    }

    // MARK: Countdown logic
    private func startCountdown() {
        animateStep(number: "3", targetValue: 1.0, index: 0)
    }

    private func animateStep(number: String, targetValue: CGFloat, index: Int) {

        countdownLabel.text = number
        countdownLabel.alpha = 0
        countdownLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

        UIView.animate(withDuration: 0.35) {
            self.countdownLabel.alpha = 1
            self.countdownLabel.transform = .identity
        }

        // If "Start" → jump to strokeEnd = 0
        if number == "Start" {

            // Instantly set ring to empty
            ringLayer.strokeEnd = 0

            // Fade & navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.finishCountdown()
            }

            return
        }

        // Smooth unwind animation for 3,2,1 only
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = ringLayer.strokeEnd
        anim.toValue = targetValue
        anim.duration = 0.6
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        ringLayer.strokeEnd = targetValue
        ringLayer.add(anim, forKey: "shrink")

        // Move to next number after 1 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay) {

            switch index {
            case 0: self.animateStep(number: "2", targetValue: 0.66, index: 1)
            case 1: self.animateStep(number: "1", targetValue: 0.33, index: 2)
            default: self.animateStep(number: "Start", targetValue: 0.0, index: 3)
            }
        }
    }

    // MARK: Fade + Navigate
    private func finishCountdown() {

        UIView.animate(withDuration: 0.4) {
            self.ringLayer.opacity = 0
            self.trackLayer.opacity = 0
            self.countdownLabel.alpha = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {

            guard let vc = self.storyboard?.instantiateViewController(
                withIdentifier: "PrepareJamViewController"
            ) else {
                return
            }

            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
    }
}
