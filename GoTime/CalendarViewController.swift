//
//  CalendarViewController.swift
//  GoTime
//
//  Created by Robert Mathews on 5/22/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import JTAppleCalendar
import CoreData

class CalendarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var tasks : [Task] = []
   var allTasks : [Task] = []
   var priorityType : [String] = ["⏬", "⬇️", "⏺", "⬆️", "⏫"]
   let formatter = DateFormatter()
   
   @IBOutlet weak var calendarView: JTAppleCalendarView!
   @IBOutlet weak var yearLabel: UILabel!
   @IBOutlet weak var monthLabel: UILabel!
   @IBOutlet weak var tableView: UITableView!
   
   override func viewWillAppear(_ animated: Bool) {
      self.tabBarController?.navigationItem.title = "Calendar"
   }
   override func viewDidLoad() {
      super.viewDidLoad()
      
      let background = CAGradientLayer().setBackground()
      background.frame = self.view.bounds
      self.view.layer.insertSublayer(background, at: 0)
      
      initCalendarView()
      self.calendarView.scrollToDate(NSDate() as Date)
      self.calendarView.selectDates([NSDate() as Date])
      
      tableView.dataSource = self
      tableView.delegate = self
      
      getData(searchDate: "")
      // Do any additional setup after loading the view, typically from a nib.
   }
   
   override func viewDidAppear(_ animated: Bool) {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      do {
         getData(searchDate: "")
         allTasks = try context.fetch(Task.fetchRequest())
         calendarView.reloadData()
         tableView.reloadData()
      }
      catch {
         print("Error: fetch failed")
      }
   }
   
   func initCalendarView() {
      calendarView.minimumLineSpacing = 0
      calendarView.minimumInteritemSpacing = 0
      calendarView.visibleDates { (visibleDates) in
         self.setupCalendarViews(from: visibleDates)
      }
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return "Tasks Due"
   }
   
   //MARK: - Tableview Delegate & Datasource
   func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
      return tasks.count
   }
   
   func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskTableViewCell

      let task = tasks[indexPath.row]
      cell.taskLabel?.text = task.name!
      let priorityIndex = Int(task.priority)
      cell.priorityLabel?.text = priorityType[priorityIndex]
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
      
   }
   
   internal func getData(searchDate: String) {
      if(searchDate != "") {
         let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         let request: NSFetchRequest<Task> = Task.fetchRequest()
         let date = formatter.date(from: searchDate)! as NSDate
         request.predicate = NSPredicate(format: "dueDate == %@ AND resolution == %@", date, "Incomplete")
         do {
            tasks = try context.fetch(request)
         }
         catch {
            print("Error: fetch failed")
         }
         tableView.reloadData()
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   func setupCalendarViews(from visibleDates: DateSegmentInfo) {
      let date = visibleDates.monthDates.first!.date
      
      formatter.dateFormat = "yyyy"
      yearLabel.text = formatter.string(from: date)
      
      formatter.dateFormat = "MMMM"
      monthLabel.text = formatter.string(from: date)
   }
   
   func setCellEntryIndicator(cell: JTAppleCell?, cellState: CellState, date: Date) {
      guard let validCell = cell as? CalendarCell else {return}
      
      var markCell = false
      for task in allTasks {
         if (task.dueDate! as Date == date && task.resolution == "Incomplete") {
             markCell = true
         }
      }
      
      if(markCell) {
         validCell.entryIndicator.isHidden = false
      }
      else {
         validCell.entryIndicator.isHidden = true
      }
   }
   
   func setCellTextColor(cell: JTAppleCell?, cellState: CellState) {
      guard let validCell = cell as? CalendarCell else {return}
      
      if(cellState.isSelected) {
         validCell.dataLabel.textColor = UIColor.black
      }
      else {
         if cellState.dateBelongsTo == .thisMonth {
            validCell.dataLabel.textColor = UIColor.white
         }
         else {
            validCell.dataLabel.textColor = UIColor.gray
         }
      }
   }
   func cellSelected(cell: JTAppleCell?, cellState: CellState) {
      guard let validCell = cell as? CalendarCell else {return}
      if(cellState.isSelected) {
         validCell.selectedView.isHidden = false
      }
      else {
         validCell.selectedView.isHidden = true
      }
   }
   
}

extension CalendarViewController: JTAppleCalendarViewDataSource {
   
   func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
      formatter.dateFormat = "MMM dd yyy"
      formatter.timeZone = Calendar.current.timeZone
      formatter.locale = Calendar.current.locale
      
      let startDate = formatter.date(from: "Jan 01 2017")
      let endDate = formatter.date(from: "Dec 31 2050")
      
      let parameters = ConfigurationParameters(startDate: startDate!, endDate: endDate!)
      return parameters
   }
}

extension CalendarViewController: JTAppleCalendarViewDelegate {
   func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
      let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "calendarCell", for: indexPath) as! CalendarCell
      cell.dataLabel.text = cellState.text
      

      cellSelected(cell: cell, cellState: cellState)
      setCellTextColor(cell: cell, cellState: cellState)
      
      setCellEntryIndicator(cell: cell, cellState: cellState, date: date)
      return cell
   }
   
   func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
      cellSelected(cell: cell, cellState: cellState)
      setCellTextColor(cell: cell, cellState: cellState)
      
      formatter.dateFormat = "MMM dd yyyy"
      let searchString = formatter.string(from: date)
      getData(searchDate: searchString)
   }
   
   func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
      cellSelected(cell: cell, cellState: cellState)
      setCellTextColor(cell: cell, cellState: cellState)
   }
   
   func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
      initCalendarView()
   }
}
