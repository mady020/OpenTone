import UIKit

class CalendarViewController: UIViewController {
    @IBOutlet weak var calendarContainer: UIView!
    private let calendarView = UICalendarView()
    private var selectedDate: DateComponents?
    private let USE_DUMMY_DATA = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendarView()
    }
    
    private func setupCalendarView() {
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.locale = Locale(identifier: "en_US")
        calendarView.fontDesign = .rounded
        calendarView.delegate = self
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
        let calendar = Calendar.current
        let today = Date()
        if let startDate = calendar.date(byAdding: .month, value: -1, to: today) {
            calendarView.availableDateRange = DateInterval(start: startDate, end: today)
        }
        
        calendarContainer.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor)
        ])
    }
    private func hasActivity(on date: Date) -> Bool {
        if USE_DUMMY_DATA {
            let calendar = Calendar.current
            return calendar.isDateInToday(date) || calendar.isDateInYesterday(date)
        } else {
            return !StreakDataModel.shared.sessions(for: date).isEmpty
        }
    }

    private func getHistoryItems(for date: Date) -> [HistoryItem] {
        if USE_DUMMY_DATA {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return [
                    HistoryItem(title: "Jam Session", subtitle: "5 min session", topic: "Mindfulness", duration: "20 min", xp: "15 XP", iconName: "mic.fill"),
                    HistoryItem(title: "Role-Play", subtitle: "3 min session", topic: "Knowledge", duration: "30 min", xp: "20 XP", iconName: "theatermasks.fill"),
                    HistoryItem(title: "Jam Session", subtitle: "4 min session", topic: "Global Warming", duration: "40 min", xp: "30 XP", iconName: "mic.fill")
                ]
            } else if calendar.isDateInYesterday(date) {
                return [
                    HistoryItem(title: "Jam Session", subtitle: "10 min session", topic: "Mindfulness", duration: "25 min", xp: "18 XP", iconName: "mic.fill"),
                    HistoryItem(title: "Role-Play", subtitle: "15 min session", topic: "Knowledge", duration: "15 min", xp: "10 XP", iconName: "theatermasks.fill")
                ]
            } else {
                return [HistoryItem(title: "Role-Play", subtitle: "5 min session", topic: "Making Friends", duration: "10 min", xp: "5 XP", iconName: "theatermasks.fill")]
            }
        } else {
            return StreakDataModel.shared.sessions(for: date).map {
                HistoryItem(title: $0.title, subtitle: $0.subtitle, topic: $0.topic, duration: "\($0.durationMinutes) min", xp: "\($0.xp) XP", iconName: $0.iconName)
            }
        }
    }
}
extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        return nil
    }
}
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        guard let dc = dateComponents, let date = Calendar.current.date(from: dc) else { return false }
        return hasActivity(on: date)
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dc = dateComponents, let date = Calendar.current.date(from: dc) else { return }
        
        let items = getHistoryItems(for: date)
        
        if let vc = storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryViewController {
            vc.items = items
            vc.selectedDate = date
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
