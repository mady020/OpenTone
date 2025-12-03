//
//  TimerManager.swift
//  OpenTone
//
//  Created by Student on 03/12/25.
//

import Foundation

protocol TimerManagerDelegate: AnyObject {
    /// called for each value in the sequence (e.g. "3", "2", "1", "Start")
    func timerManagerDidUpdateCountdownText(_ text: String)

    /// called every second while the main timer is running with formatted "MM:SS"
    func timerManagerDidUpdateMainTimer(_ formattedTime: String)

    /// called once when the sequence completes and the main timer is about to start
    func timerManagerDidStartMainTimer()

    /// called when the main timer finishes
    func timerManagerDidFinish()
}

final class TimerManager {

    weak var delegate: TimerManagerDelegate?

    private var sequenceTimer: Timer?
    private var mainTimer: Timer?

    private let totalSeconds: Int
    private var secondsLeft: Int

    private let sequenceValues: [String]

    private var isRunning = false

    init(totalSeconds: Int = 120, sequence: [String] = ["3", "2", "1", "Start"]) {
        self.totalSeconds = totalSeconds
        self.secondsLeft = totalSeconds
        self.sequenceValues = sequence
    }

    // MARK: - Public API

    /// Start the full flow: sequence (3,2,1,Start) -> main timer
    func start() {
        guard !isRunning else { return }
        isRunning = true
        startSequence()
    }

    /// Stop everything and reset internal state
    func reset() {
        stopTimers()
        secondsLeft = totalSeconds
        isRunning = false
    }

    // MARK: - Private

    private func stopTimers() {
        sequenceTimer?.invalidate()
        mainTimer?.invalidate()
        sequenceTimer = nil
        mainTimer = nil
    }

    private func startSequence() {
        var index = 0

        // Use scheduledTimer on main run loop so delegate UI updates happen on main thread
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if index >= self.sequenceValues.count {
                timer.invalidate()
                self.delegate?.timerManagerDidStartMainTimer()
                self.startMainTimer()
                return
            }

            let text = self.sequenceValues[index]
            self.delegate?.timerManagerDidUpdateCountdownText(text)
            index += 1
        }
    }

    private func startMainTimer() {
        secondsLeft = totalSeconds

        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            self.secondsLeft -= 1

            if self.secondsLeft <= 0 {
                timer.invalidate()
                self.delegate?.timerManagerDidFinish()
            } else {
                self.delegate?.timerManagerDidUpdateMainTimer(self.format(self.secondsLeft))
            }
        }
    }

    private func format(_ secs: Int) -> String {
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }
}
