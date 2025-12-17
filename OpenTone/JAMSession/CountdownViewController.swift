//
//  CountdownViewController.swift
//  OpenTone
//
//  Created by Student on 04/12/25.
//
//
//  CountdownViewController.swift
//  OpenTone
//

import UIKit

final class CountdownViewController: UIViewController {

    @IBOutlet weak var circleContainer: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!

    private let ringLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private var didSetup = false

    private let rightRevealDuration: CFTimeInterval = 0.35
    private let fadeDuration: CFTimeInterval = 0.5
    private let stepDelay: Double = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        bottomLabel.text = "Speech Time"

        countdownLabel.text = "Ready"
        countdownLabel.font = .systemFont(ofSize: 70, weight: .semibold)
        countdownLabel.alpha = 1
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetup {
            setupRing()
            didSetup = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.tabBar.isHidden = true
        animateRightHalf()
    }

    private func setupRing() {

        let thickness: CGFloat = 26
        let radius =
            min(circleContainer.bounds.width, circleContainer.bounds.height) / 2
            - thickness / 2

        let path = UIBezierPath(
            arcCenter: CGPoint(
                x: circleContainer.bounds.midX,
                y: circleContainer.bounds.midY
            ),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(
            red: 0.9, green: 0.8, blue: 1, alpha: 1
        ).cgColor
        trackLayer.lineWidth = thickness
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round

        ringLayer.path = path.cgPath
        ringLayer.strokeColor = UIColor(
            red: 0.42, green: 0.05, blue: 0.68, alpha: 1
        ).cgColor
        ringLayer.lineWidth = thickness
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = .round
        ringLayer.strokeStart = 0
        ringLayer.strokeEnd = 0.5

        circleContainer.layer.addSublayer(trackLayer)
        circleContainer.layer.addSublayer(ringLayer)
    }

    private func animateRightHalf() {

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0.5
        anim.toValue = 1.0
        anim.duration = rightRevealDuration
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        ringLayer.strokeEnd = 1
        ringLayer.add(anim, forKey: "rightReveal")

        DispatchQueue.main.asyncAfter(
            deadline: .now() + rightRevealDuration + 0.2
        ) {
            self.fadeOutReady()
        }
    }

    private func fadeOutReady() {
        UIView.animate(withDuration: 0.4, animations: {
            self.countdownLabel.alpha = 0
        }) { _ in
            self.animateNumber("3", step: 0)
        }
    }

    private func animateNumber(_ text: String, step: Int) {

        countdownLabel.text = text
        countdownLabel.font =
            text == "Start"
            ? .systemFont(ofSize: 70, weight: .semibold)
            : .systemFont(ofSize: 95, weight: .bold)

        countdownLabel.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.countdownLabel.alpha = 1
        }

        if text == "Start" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.goToStartScreen()
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay) {
            switch step {
            case 0: self.animateNumber("2", step: 1)
            case 1: self.animateNumber("1", step: 2)
            default: self.animateNumber("Start", step: 3)
            }
        }
    }

    private func goToStartScreen() {

        UIView.animate(withDuration: 0.3) {
            self.countdownLabel.alpha = 0
            self.ringLayer.opacity = 0
            self.trackLayer.opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {

            guard let nav = self.navigationController,
                  let root = nav.viewControllers.first,
                  let prepareVC = self.storyboard?.instantiateViewController(
                    withIdentifier: "PrepareJamViewController"
                  ) as? PrepareJamViewController,
                  let startVC = self.storyboard?.instantiateViewController(
                    withIdentifier: "StartJamViewController"
                  ) as? StartJamViewController
            else { return }

            nav.setViewControllers([root, prepareVC, startVC], animated: true)
        }
    }
}
