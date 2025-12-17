//
//  CalendarViewController.swift
//  OpenTone
//
//  Created by Student on 11/12/25.
//

import UIKit

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var calendarContainer: UIView!
    
    private let calendarView = UICalendarView()
    private var selectedDate: DateComponents?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.locale = Locale(identifier: "en_US")
        calendarView.fontDesign = .rounded
        
        // SET DELEGATES (important)
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
        calendarView.delegate = self
        
        // Add inside container
        calendarContainer.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor)
        ])
    }
}

extension CalendarViewController: UICalendarSelectionSingleDateDelegate {

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {

        selectedDate = dateComponents

        if let dc = dateComponents {
            print("SELECTED:", dc)
           
            calendarView.reloadDecorations(forDateComponents: [dc], animated: true)
        }
    }
}


extension CalendarViewController: UICalendarViewDelegate {

    func calendarView(_ calendarView: UICalendarView,
                      decorationFor dateComponents: DateComponents)
    -> UICalendarView.Decoration? {

        guard let selected = selectedDate,
              selected.day == dateComponents.day,
              selected.month == dateComponents.month,
              selected.year == dateComponents.year else {
            return nil
        }

        // PURPLE circle
        return .customView {
            let v = UIView()
//            self.calendarContainer.backgroundColor  = .systemPurple
            v.backgroundColor = UIColor.systemPurple.withAlphaComponent(1)
            v.layer.cornerRadius = 18

            NSLayoutConstraint.activate([
                v.widthAnchor.constraint(equalToConstant: 36),
                v.heightAnchor.constraint(equalToConstant: 36)
            ])

            return v
        }
    }
}
