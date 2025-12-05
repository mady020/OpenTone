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
    private var didSetup = false

   
    private let halfFillDuration: CFTimeInterval = 0.37
    private let rightAppearDuration: CFTimeInterval = 0.37
    private let fadeDuration: CFTimeInterval = 0.50
    private let stepDelay: Double = 1.02

   
    private let readyPopDuration: CFTimeInterval = 0.50
    private let readyVisibleHold: CFTimeInterval = 0.50

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        bottomLabel.text = "Preparation Time"
        countdownLabel.text = ""
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetup {
            setupLayers()
            setInitialLeftHalf()
            didSetup = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateRightHalf()
    }


    private func setupLayers() {

        let thickness: CGFloat = 26
        let path = makeCirclePath()

        // TRACK
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(red: 0.90, green: 0.80, blue: 1.0, alpha: 1).cgColor
        trackLayer.lineWidth = thickness
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        trackLayer.frame = circleContainer.bounds

        // RING
        ringLayer.path = path.cgPath
        ringLayer.strokeColor = UIColor(red: 0.42, green: 0.05, blue: 0.68, alpha: 1).cgColor
        ringLayer.lineWidth = thickness
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = .round
        ringLayer.frame = circleContainer.bounds

        circleContainer.layer.addSublayer(trackLayer)
        circleContainer.layer.addSublayer(ringLayer)
    }

    private func makeCirclePath() -> UIBezierPath {

        let thickness: CGFloat = 26
        let radius = min(circleContainer.bounds.width, circleContainer.bounds.height) / 2 - thickness / 2

        return UIBezierPath(
            arcCenter: CGPoint(x: circleContainer.bounds.midX, y: circleContainer.bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,        // 12 o'clock
            endAngle: 1.5 * .pi,         // full circle
            clockwise: true
        )
    }


    private func setInitialLeftHalf() {
        ringLayer.strokeStart = 0.0
        ringLayer.strokeEnd = 0.5
    }

    private func animateRightHalf() {

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0.5
        anim.toValue   = 1.0
        anim.duration  = rightAppearDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        ringLayer.strokeEnd = 1.0
        ringLayer.add(anim, forKey: "rightHalfReveal")

        DispatchQueue.main.asyncAfter(deadline: .now() + rightAppearDuration + 0.05) {
            self.showReady()
        }
    }


    private func showReady() {

        countdownLabel.text = "Ready"
        countdownLabel.font = UIFont.systemFont(ofSize: 70, weight: .semibold)
        countdownLabel.alpha = 0
        countdownLabel.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        // SLOWER animation
        UIView.animate(withDuration: readyPopDuration) {
            self.countdownLabel.alpha = 1
            self.countdownLabel.transform = .identity
        }

        // HOLD Ready on screen longer
        DispatchQueue.main.asyncAfter(deadline: .now() + readyPopDuration + readyVisibleHold) {
            self.startCountdown()
        }
    }

    private func startCountdown() {
        animateNumber("3", fadeTo: 0.33, step: 0)
    }

    private func animateNumber(_ number: String, fadeTo: CGFloat, step: Int) {

        countdownLabel.text = number
        countdownLabel.font =
            number == "Start"
            ? UIFont.systemFont(ofSize: 70, weight: .semibold)
            : UIFont.systemFont(ofSize: 95, weight: .bold)

        countdownLabel.alpha = 0
        countdownLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

        UIView.animate(withDuration: 0.30 + 0.02) {
            self.countdownLabel.alpha = 1
            self.countdownLabel.transform = .identity
        }

        if number == "Start" {
            ringLayer.strokeStart = 1.0
            ringLayer.strokeEnd = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + 0.02) {
                self.goNext()
            }
            return
        }

        // Fade left side first
        let fade = CABasicAnimation(keyPath: "strokeStart")
        fade.fromValue = ringLayer.presentation()?.strokeStart ?? ringLayer.strokeStart
        fade.toValue   = fadeTo
        fade.duration  = fadeDuration
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false

        ringLayer.strokeStart = fadeTo
        ringLayer.add(fade, forKey: "fadeLeftHalf")

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay) {
            switch step {
            case 0: self.animateNumber("2", fadeTo: 0.66, step: 1)
            case 1: self.animateNumber("1", fadeTo: 1.0, step: 2)
            default: self.animateNumber("Start", fadeTo: 1.0, step: 3)
            }
        }
    }


    private func goNext() {

        UIView.animate(withDuration: 0.35) {
            self.countdownLabel.alpha = 0
            self.ringLayer.opacity = 0
            self.trackLayer.opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 0.02) {

            guard let vc =
                self.storyboard?.instantiateViewController(withIdentifier: "PrepareJamViewController")
            else { return }

            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
    }
}
