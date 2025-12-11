//
//  CountdownViewController.swift
//  OpenTone
//
//  Created by Student on 04/12/25.
//

import UIKit

class CountdownViewController: UIViewController {

    enum CountdownMode {
        case preparation
        case speech
    }

    var mode: CountdownMode = .preparation

    // ⭐ ADDED: topic passed from Prepare screen
    var topicText: String?

    @IBOutlet weak var circleContainer: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!

    private let ringLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private var didSetup = false

    private let rightAppearDuration: CFTimeInterval = 0.37
    private let fadeDuration: CFTimeInterval = 0.50
    private let stepDelay: Double = 1.02

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        bottomLabel.text = (mode == .preparation) ? "Preparation Time" : "Speech Time"

        // READY IS ALWAYS VISIBLE INITIALLY
        countdownLabel.text = "Ready"
        countdownLabel.font = UIFont.systemFont(ofSize: 70, weight: .semibold)
        countdownLabel.alpha = 1
        countdownLabel.transform = .identity
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
        tabBarController?.tabBar.isHidden = true
    }

    private func setupLayers() {

        let thickness: CGFloat = 26
        let path = makeCirclePath()

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(red: 0.90, green: 0.80, blue: 1.0, alpha: 1).cgColor
        trackLayer.lineWidth = thickness
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        trackLayer.frame = circleContainer.bounds

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
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
    }

    private func setInitialLeftHalf() {
        ringLayer.strokeStart = 0.0
        ringLayer.strokeEnd = 0.5
    }

    // MARK: - RIGHT HALF ANIMATION
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

        // Fade out READY after right half completes
        DispatchQueue.main.asyncAfter(deadline: .now() + rightAppearDuration + 0.2) {
            self.fadeOutReady()
        }
    }

    // MARK: - READY FADE OUT
    private func fadeOutReady() {

        UIView.animate(withDuration: 0.6, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.countdownLabel.alpha = 0
        }, completion: { _ in
            self.startCountdown()
        })
    }

    // MARK: - COUNTDOWN (3 → 2 → 1 → Start)
    private func startCountdown() {
        animateNumber("3", fadeTo: 0.33, step: 0)
    }

    private func animateNumber(_ number: String, fadeTo: CGFloat, step: Int) {

        countdownLabel.text = number
        countdownLabel.font =
            (number == "Start")
            ? UIFont.systemFont(ofSize: 70, weight: .semibold)
            : UIFont.systemFont(ofSize: 95, weight: .bold)

        countdownLabel.alpha = 0

        UIView.animate(withDuration: 0.32) {
            self.countdownLabel.alpha = 1
        }

        if number == "Start" {

            ringLayer.strokeStart = 1.0
            ringLayer.strokeEnd = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
                self.goNext()
            }
            return
        }

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

    // MARK: - NAVIGATION (Fixed)
    private func goNext() {

        UIView.animate(withDuration: 0.35) {
            self.countdownLabel.alpha = 0
            self.ringLayer.opacity = 0
            self.trackLayer.opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {

            guard let nav = self.navigationController else { return }
            let root = nav.viewControllers.first!

            switch self.mode {

            case .preparation:
                guard let prepareVC =
                    self.storyboard?.instantiateViewController(withIdentifier: "PrepareJamViewController")
                        as? PrepareJamViewController else { return }

                
                nav.setViewControllers([root, prepareVC], animated: true)

            case .speech:
                guard let prepareVC =
                    self.storyboard?.instantiateViewController(withIdentifier: "PrepareJamViewController")
                        as? PrepareJamViewController else { return }

                guard let startVC =
                    self.storyboard?.instantiateViewController(withIdentifier: "StartJamViewController")
                        as? StartJamViewController else { return }

                // ⭐ MAIN FIX – pass topic to StartJam
                if let t = self.topicText, !t.isEmpty {
                    startVC.topicText = t
                }

                nav.setViewControllers([root, prepareVC, startVC], animated: true)
            }
        }
    }
}
