
import Foundation

struct HistoryItem {
    let title: String          // e.g. "2 Min Session"
    let subtitle: String       // e.g. "You completed 2 min session"
    let topic: String          // e.g. "Time Travel"
    let duration: String       // e.g. "2 min"
    let xp: String             // e.g. "15 XP"
    let iconName: String       // e.g. "mic.fill"

    init(title: String,
         subtitle: String,
         topic: String,
         duration: String,
         xp: String,
         iconName: String) {

        self.title = title
        self.subtitle = subtitle
        self.topic = topic
        self.duration = duration
        self.xp = xp
        self.iconName = iconName
    }
}
extension HistoryItem {
    var durationText: String { duration }
    var gainedText: String { xp }
}

