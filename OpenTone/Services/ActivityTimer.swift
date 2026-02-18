import Foundation

final class ActivityTimer {
    private var startTime: Date?
    
    func start() {
        startTime = Date()
    }
    
    func stop() -> TimeInterval {
        guard let start = startTime else { return 0 }
        let duration = Date().timeIntervalSince(start)
        startTime = nil
        return duration
    }
    
    var isRunning: Bool {
        startTime != nil
    }
}
