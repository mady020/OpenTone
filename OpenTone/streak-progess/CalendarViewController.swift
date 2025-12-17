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
           
           // SET SELECTION DELEGATE ONLY
           calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
           
           // LIMIT CALENDAR TO TODAY ONLY
           let calendar = Calendar.current
           let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
           
           if let todayDate = calendar.date(from: todayComponents) {
               calendarView.availableDateRange = DateInterval(
                   start: todayDate,
                   end: todayDate
               )
           }
           
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
           if let dc = dateComponents,
              let date = Calendar.current.date(from: dc) {

               let sessions =
                   StreakDataModel.shared.sessions(for: date)

               let items = sessions.map {
                   HistoryItem(
                       title: $0.title,
                       subtitle: $0.subtitle,
                       topic: $0.topic,
                       duration: "\($0.durationMinutes) min",
                       xp: "\($0.xp) XP",
                       iconName: $0.iconName
                   )
               }

               let vc = storyboard?.instantiateViewController(
                   withIdentifier: "HistoryViewController"
               ) as! HistoryViewController

               vc.items = items
               vc.selectedDate = date

               navigationController?.pushViewController(vc, animated: true)
           }

           selectedDate = dateComponents

           if let dc = dateComponents {
               print("SELECTED:", dc)
           }
       }
   }
