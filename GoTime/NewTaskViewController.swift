//
//  SecondViewController.swift
//  GoTime
//
//  Created by Robert Mathews on 5/22/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseDatabase

class NewTaskViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MyProtocol {
   @IBOutlet var taskName: UITextField!
   @IBOutlet weak var priorityControl: UISegmentedControl!
   @IBOutlet weak var dueDate: UIDatePicker!
   @IBOutlet weak var groupButton: UIButton!
   @IBOutlet weak var reminderPicker: UIPickerView!
   @IBOutlet weak var commentTextView: UITextView!
   @IBOutlet weak var scrollView: UIScrollView!
   
   var pickerData: [String] = ["None", "When Due", "15 Mins Before", "30 Mins Before", "1 Hour Before", "Day Before"]
   var savedTaskText: String = ""
   var userData: UserData = UserData()
   var entries: [Entry] = []
   
   @IBAction func groupButtonPressed(_ sender: UIButton) {
      if(taskName.text?.isEmpty)! {
      }
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      self.reminderPicker.delegate = self
      self.reminderPicker.dataSource = self
      self.commentTextView.delegate = self
      self.taskName.delegate = self
      
      let background = CAGradientLayer().setBackground()
      background.frame = self.view.bounds
      self.view.layer.insertSublayer(background, at: 0)
      
      NotificationCenter.default.addObserver(self, selector: #selector(NewTaskViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(NewTaskViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

      
      let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
      //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
      //tap.cancelsTouchesInView = false
      view.addGestureRecognizer(tap)
      
      // Do any additional setup after loading the view, typically from a nib.
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
      
      scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height+300)
   }
   
   func dismissKeyboard() {
      //Causes the view (or one of its embedded text fields) to resign the first responder status.
      view.endEditing(true)
   }
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      self.view.endEditing(true)
      return false
   }
   
   func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      guard let text = taskName.text else { return true }
      let newLength = text.count + string.count - range.length
      return newLength <= 35 // Bool
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      do {
         userData = try context.fetch(UserData.fetchRequest()).first!
         entries = try context.fetch(Entry.fetchRequest())
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
         })
      }
      catch {
         print("Error: fetch failed")
      }
   }
   
   override func viewWillAppear(_ animated: Bool) {
      getData()
      self.taskName.text = savedTaskText
   }
   
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
   }
   
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
      return pickerData.count
   }
   
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
      return pickerData[row]
   }
   
   @IBAction func addTaskButtonPressed(_ sender: UIButton) {
      if(!(taskName.text?.isEmpty)!) {
         let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         
         userData.numTasks += 1
         let task = Task(context: context)
         task.name = taskName.text!
         task.priority = Double(priorityControl.selectedSegmentIndex)
         task.group = groupButton.currentTitle
         setReminder(dueDate: dueDate.date, reminder: reminderPicker, task: task)
         let formatter = DateFormatter()
         formatter.dateFormat = "MMM dd yyyy"
         let dueDateString = formatter.string(from: dueDate.date as Date)
         task.dueDate = formatter.date(from: dueDateString)! as NSDate
         let dateCreatedString = formatter.string(from: NSDate() as Date)
         task.dateCreated = formatter.date(from: dateCreatedString)! as NSDate
         task.timeCreated = NSDate()
         
         task.resolution = "Incomplete"
         task.id = userData.numTasks
         var entryExists = false
         var taskEntry:Entry = Entry()
         
         for entry in entries {
            let comparison = NSCalendar.current.compare(NSDate() as Date, to: entry.entryDate! as Date, toGranularity: .day)
            switch comparison {
            case .orderedSame:
               entryExists = true
               taskEntry = entry
            default:
               continue
            }
         }
         if(!entryExists) {
            taskEntry = Entry(context: context)
            taskEntry.entryDate = task.dateCreated
            if(taskEntry.createdTaskIds == nil) {
               taskEntry.createdTaskIds = [Double(task.id)]
            }
            if(taskEntry.completedTaskIds == nil) {
               taskEntry.completedTaskIds = []
            }
         }
         else {
            var toAppend:[Double] = taskEntry.createdTaskIds!
            toAppend.append(Double(task.id))
            taskEntry.setValue(toAppend, forKey: "createdTaskIds")
         }
         userData.pointScore += 1
         if(userData.loggedIn) {
            Database.database().reference().child("users").child(userData.uid!).child("pointScore").setValue(userData.pointScore)
         }
         (UIApplication.shared.delegate as! AppDelegate).saveContext()
         navigationController!.popViewController(animated: true)
      }
      else {
         let alert = UIAlertController(title: "Error", message: "Task name cannot be empty", preferredStyle: UIAlertControllerStyle.alert)
         alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
         self.present(alert, animated: true, completion: nil)
      }

   }
   
   func setReminder(dueDate: Date, reminder: UIPickerView, task: Task) {
      var row:NSInteger
      
      row = reminder.selectedRow(inComponent: 0)
      var stringToPrint = pickerData[row]
      var remindTime:Date
      var setTime = true
      
      switch stringToPrint {
      case "When Due":
         remindTime = dueDate
      case "15 Mins Before":
         remindTime = dueDate.addingTimeInterval(-60*15)
      case "30 Mins Before":
         remindTime = dueDate.addingTimeInterval(-60*30)
      case "1 Hour Before":
         remindTime = dueDate.addingTimeInterval(-60*60)
      case "Day Before":
         remindTime = dueDate.addingTimeInterval(-60*60*24)
      default:
         remindTime = dueDate
         setTime = false
      }
      
      if(setTime)
      {
         let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
         let components = NSCalendar.current.dateComponents(unitFlags, from: remindTime)
         
         let content = UNMutableNotificationContent()
         content.title = "" + task.name! + " is due"
         content.body = stringToPrint
         content.badge = 1;
         
         let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
         let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
         UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   func setTextBack(taskSavedText: String) {
      self.savedTaskText = taskSavedText
   }
   
   func setGroupButton(groupButton: String) {
      self.groupButton.setTitle(groupButton, for: .normal)
   }
   
   
   func textViewDidBeginEditing(_ textView: UITextView) {
      //clear placeholder text
      if(commentTextView.text == "Additional comments...") {
         commentTextView.text = ""
      }
   }
   
   func keyboardWillShow(notification: NSNotification) {
      if(!self.taskName.isEditing) {
         if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
               self.view.frame.origin.y -= keyboardSize.height
            }
         }
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
         if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
               self.view.frame.origin.y += keyboardSize.height
            }
         }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "showGroupsVC" {
         let groupsVC: AddGroupVC = segue.destination as! AddGroupVC
         groupsVC.myProtocol = self
         groupsVC.taskText = self.taskName.text!
      }
   }
   
}

