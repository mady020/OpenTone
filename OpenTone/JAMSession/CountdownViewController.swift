
import UIKit

final class CountdownViewController: UIViewController {

    var isSpeechCountdown: Bool = false

    @IBOutlet weak var circleContainer: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!

    private let ringLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private var didSetup = false

    private let rightRevealDuration: CFTimeInterval = 0.37
    private let fadeDuration: CFTimeInterval = 0.50
    private let stepDelay: Double = 1.02

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
            setInitialLeftHalf()
            didSetup = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tabBarController?.tabBar.isHidden = true
        animateRightHalf()
    }

    // MARK: - Ring Setup

    private func setupRing() {

        let thickness: CGFloat = 26
        let radius =
            min(circleContainer.bounds.width, circleContainer.bounds.height) / 2
            - thickness / 2

        let path = UIBezierPath(
            arcCenter: CGPoint(x: circleContainer.bounds.midX,
                               y: circleContainer.bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor(
            red: 242/255,
            green: 238/255,
            blue: 255/255,
            alpha: 1
        ).cgColor
        trackLayer.lineWidth = thickness
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round

        ringLayer.path = path.cgPath
        ringLayer.strokeColor = UIColor(
            red: 86/255,
            green: 61/255,
            blue: 189/255,
            alpha: 1
        ).cgColor
        ringLayer.lineWidth = thickness
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = .round

        circleContainer.layer.addSublayer(trackLayer)
        circleContainer.layer.addSublayer(ringLayer)
    }

    private func setInitialLeftHalf() {
        ringLayer.strokeStart = 0.0
        ringLayer.strokeEnd = 0.5
    }

    // MARK: - Countdown Animation

    private func animateRightHalf() {

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0.5
        anim.toValue = 1.0
        anim.duration = rightRevealDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        ringLayer.strokeEnd = 1.0
        ringLayer.add(anim, forKey: "rightReveal")

        DispatchQueue.main.asyncAfter(
            deadline: .now() + rightRevealDuration + 0.2
        ) {
            self.fadeOutReady()
        }
    }

    private func fadeOutReady() {
        UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseInOut]) {
            self.countdownLabel.alpha = 0
        } completion: { _ in
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
            ? .systemFont(ofSize: 70, weight: .semibold)
            : .systemFont(ofSize: 95, weight: .bold)

        countdownLabel.alpha = 0
        UIView.animate(withDuration: 0.32) {
            self.countdownLabel.alpha = 1
        }

        if number == "Start" {

            ringLayer.strokeStart = 1.0
            ringLayer.strokeEnd = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
                self.goToStartScreen()
            }
            return
        }

        let fade = CABasicAnimation(keyPath: "strokeStart")
        fade.fromValue = ringLayer.presentation()?.strokeStart ?? ringLayer.strokeStart
        fade.toValue = fadeTo
        fade.duration = fadeDuration
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false

        ringLayer.strokeStart = fadeTo
        ringLayer.add(fade, forKey: "fadeLeft")

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay) {
            switch step {
            case 0: self.animateNumber("2", fadeTo: 0.66, step: 1)
            case 1: self.animateNumber("1", fadeTo: 1.0, step: 2)
            default: self.animateNumber("Start", fadeTo: 1.0, step: 3)
            }
        }
    }

    private func goToStartScreen() {

        guard isSpeechCountdown else { return }

        DispatchQueue.main.async {

            UIView.animate(withDuration: 0.35) {
                self.countdownLabel.alpha = 0
                self.ringLayer.opacity = 0
                self.trackLayer.opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {

                guard let startVC = self.storyboard?
                    .instantiateViewController(
                        withIdentifier: "StartJamViewController"
                    ) as? StartJamViewController else { return }
                
                self.navigationController?.pushViewController(
                    startVC,
                    animated: true
                )
            }
        }
    }
}
