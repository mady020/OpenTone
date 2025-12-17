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

           selectedDate = dateComponents

           if let dc = dateComponents {
               print("SELECTED:", dc)
           }
       }
   }
