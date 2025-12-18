//
//  ViewController.swift
//  OpenTone
//
//  Created by M S on 16/12/25.
//


import UIKit
import AVFoundation

final class AICallController: UIViewController {
    

    // MARK: - Audio
    private let audioEngine = AVAudioEngine()
    private var isMuted = false

    // MARK: - Animation
    private var displayLink: CADisplayLink?
    private let ringLayer = CAShapeLayer()

    // MARK: - State
    private var smoothedLevel: CGFloat = 0.12
    private let smoothingFactor: CGFloat = 0.15

    private let baseRadius: CGFloat = 90
    private let maxExpansion: CGFloat = 45

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.screenBackground

        setupRing()
        setupButtons()
        setupAudioSession()
        setupAudio()
        startDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
        audioEngine.stop()
    }

    // MARK: - Ring
    private func setupRing() {
        ringLayer.strokeColor = AppColors.primary.cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 6
        ringLayer.lineCap = .round
        ringLayer.opacity = 0.9

        view.layer.addSublayer(ringLayer)
    }

    private func updateRing(radius: CGFloat) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )

        ringLayer.path = path.cgPath
    }

    // MARK: - Buttons
    private func setupButtons() {
        let muteButton = makeButton(
            symbol: "mic.fill",
            action: #selector(toggleMute)
        )
        muteButton.frame.origin = CGPoint(x: 40, y: view.bounds.height - 120)

        let closeButton = makeButton(
            symbol: "xmark",
            action: #selector(closeTapped)
        )
        closeButton.frame.origin = CGPoint(
            x: view.bounds.width - 96,
            y: view.bounds.height - 120
        )

        view.addSubview(muteButton)
        view.addSubview(closeButton)
    }

    private func makeButton(symbol: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        button.layer.cornerRadius = 28
        button.backgroundColor = AppColors.cardBackground
        button.layer.borderColor = AppColors.cardBorder.cgColor
        button.layer.borderWidth = 1

        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = AppColors.textPrimary
        button.addTarget(self, action: action, for: .touchUpInside)

        return button
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker]
        )
        try? session.setActive(true)
    }

    // MARK: - Audio Engine
    private func setupAudio() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        guard format.sampleRate > 0 else { return }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.processAudio(buffer)
        }

        try? audioEngine.start()
    }

    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted,
              let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0

        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }

        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(max(rms, 0.000_001))
        let normalized = max(0, min(1, (db + 50) / 50))

        DispatchQueue.main.async {
            self.smoothedLevel +=
                (CGFloat(normalized) - self.smoothedLevel) * self.smoothingFactor
        }
    }

    // MARK: - Animation Loop
    private func startDisplayLink() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateAnimation)
        )
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateAnimation() {
        let radius = baseRadius + smoothedLevel * maxExpansion
        updateRing(radius: radius)
    }

    // MARK: - Actions
    @objc private func toggleMute(_ sender: UIButton) {
        isMuted.toggle()
        let symbol = isMuted ? "mic.slash.fill" : "mic.fill"
        sender.setImage(UIImage(systemName: symbol), for: .normal)
        smoothedLevel = 0.12
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

