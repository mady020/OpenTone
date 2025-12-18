//
//  TimerManager.swift
//  OpenTone
//
//  Created by Student on 03/12/25.
//

import Foundation

protocol TimerManagerDelegate: AnyObject {
    func timerManagerDidUpdateMainTimer(_ formattedTime: String)
    func timerManagerDidStartMainTimer()
    func timerManagerDidFinish()
}

final class TimerManager {

    weak var delegate: TimerManagerDelegate?

    private var mainTimer: Timer?
    private let totalSeconds: Int
    private var secondsLeft: Int

    private var isRunning = false

    init(totalSeconds: Int = 120) {
        self.totalSeconds = totalSeconds
        self.secondsLeft = totalSeconds
    }

    func start(from seconds: Int) {
        guard !isRunning else { return }
        secondsLeft = max(0, seconds)
        isRunning = true
        delegate?.timerManagerDidStartMainTimer()
        startMainTimer()
    }

    func reset() {
        mainTimer?.invalidate()
        mainTimer = nil
        secondsLeft = totalSeconds
        isRunning = false
    }

    private func startMainTimer() {
        mainTimer?.invalidate()

        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            self.secondsLeft -= 1

            if self.secondsLeft <= 0 {
                timer.invalidate()
                self.isRunning = false
                self.delegate?.timerManagerDidFinish()
            } else {
                self.delegate?.timerManagerDidUpdateMainTimer(self.format(self.secondsLeft))
            }
        }
    }

    private func format(_ secs: Int) -> String {
        String(format: "%02d:%02d", secs / 60, secs % 60)
    }
}

