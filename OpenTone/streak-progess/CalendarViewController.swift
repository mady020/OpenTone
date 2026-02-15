import UIKit

class CalendarViewController: UIViewController {
    @IBOutlet weak var calendarContainer: UIView!
    private let calendarView = UICalendarView()
    private var selectedDate: DateComponents?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.screenBackground
        setupCalendarView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            view.backgroundColor = AppColors.screenBackground
        }
    }

    private func setupCalendarView() {
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.locale = Locale(identifier: "en_US")
        calendarView.fontDesign = .rounded
        calendarView.tintColor = AppColors.primary
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
        return !StreakDataModel.shared.sessions(for: date).isEmpty
    }

    private func getHistoryItems(for date: Date) -> [HistoryItem] {
        return StreakDataModel.shared.sessions(for: date).map {
            // Infer activity type from icon name
            let activityType: ActivityType?
            switch $0.iconName {
            case "mic.fill":
                activityType = .jam
            case "person.2.fill", "person.fill":
                activityType = .roleplay
            case "phone.fill":
                activityType = .call
            default:
                activityType = nil
            }

            return HistoryItem(
                title: $0.title,
                subtitle: $0.subtitle,
                topic: $0.topic,
                duration: "\($0.durationMinutes) min",
                xp: "\($0.xp) XP",
                iconName: $0.iconName,
                date: $0.date,
                activityType: activityType
            )
        }
    }
}

extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        if hasActivity(on: date) {
            return .default(color: AppColors.primary)
        }
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
