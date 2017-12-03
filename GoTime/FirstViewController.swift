//
//  FirstViewController.swift
//  GoTime
//
//  Created by Robert Mathews on 5/29/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var tasks : [Task] = []
   var groups : [Group] = []
   var priorityType : [String] = ["⏬", "⬇️", "⏺", "⬆️", "⏫"]
   var userData: [UserData] = []
   var User: UserData = UserData()
   var entries: [Entry] = []
   var selectedIndexPath:IndexPath = IndexPath()
   @IBOutlet weak var pointScore: UILabel!
   
   
   @IBOutlet weak var tableView: UITableView!
   override func viewDidLoad() {
      super.viewDidLoad()
      tableView.dataSource = self
      tableView.delegate = self
      self.tabBarController?.navigationItem.title = "Tasks"
      
      let background = CAGradientLayer().setBackground()
      background.frame = self.view.bounds
      self.view.layer.insertSublayer(background, at: 0)
      // Do any additional setup after loading the view, typically from a nib.
   }
   
   override func viewWillAppear(_ animated: Bool) {
      //get data from core data
      getData()
      //reload table view
      tableView.reloadData()
      self.tabBarController?.navigationItem.title = "Tasks"
   }

   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      var count = 0;
      tasks = tasks.sorted(by: {$0.group! < $1.group!})
      for task in tasks {
         if task.group == groups[section].name {
            count += 1
         }
      }
      return count
   }
   
   func numberOfSections(in tableView: UITableView) -> Int {
      let toReturn = groups.count
      return toReturn
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskTableViewCell
      
      let groupFilter = groups[indexPath.section].name
      var cellTask: [Task] = tasks.filter { $0.group == groupFilter }
      
      let task = cellTask[indexPath.row]
      cell.taskLabel?.text = task.name!
      let priorityIndex = Int(task.priority)
      cell.priorityLabel?.text = priorityType[priorityIndex]
      
      return cell;
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      let request: NSFetchRequest<Task> = Task.fetchRequest()
      let filterString = "Incomplete"
      request.predicate = NSPredicate(format: "resolution == %@", filterString)
      do {
         tasks = try context.fetch(request)
         groups = try context.fetch(Group.fetchRequest())
         userData = try context.fetch(UserData.fetchRequest())
         entries = try context.fetch(Entry.fetchRequest())
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
         })
         if (groups.count == 0) {
            initializeGroups()
         }
         if (userData.count == 0) {
            initializeUserData()
         }
      }
      catch {
         print("Error: fetch failed")
      }
      User = userData.first!
      pointScore.text = String(describing: User.pointScore)
   }
   
   func addTaskToCompletedEntry(task: Task) {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
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
         taskEntry.entryDate = task.dateCompleted
         if(taskEntry.completedTaskIds == nil) {
            taskEntry.completedTaskIds = [Double(task.id)]
         }
         if(taskEntry.createdTaskIds == nil) {
            taskEntry.createdTaskIds = []
         }
      }
      else {
         var toAppend:[Double] = taskEntry.completedTaskIds!
         toAppend.append(Double(task.id))
         taskEntry.setValue(toAppend, forKey: "completedTaskIds")
      }
   }
   
   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return 25;
   }
   
   //may need to keep for when app first starts
   private func initializeUserData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      let userData = UserData(context: context)
      
      userData.daysLogged = 0
      userData.numTasks = 0
      userData.pointScore = 0
      userData.loggedIn = false
      
      (UIApplication.shared.delegate as! AppDelegate).saveContext()

      getData()
      tableView.reloadData()
    }
   
   //may need to keep for when app first starts
   private func initializeGroups() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      
      let group = Group(context: context)
      group.name = "None"
      (UIApplication.shared.delegate as! AppDelegate).saveContext()
      
      getData()
      tableView.reloadData()
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
   {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      
      if (editingStyle == UITableViewCellEditingStyle.delete)
      {
         let groupFilter = groups[indexPath.section].name
         var cellTask: [Task] = tasks.filter { $0.group == groupFilter }
         let task = cellTask[indexPath.row]
         
         for entry in entries {
            //print(entry.completedTaskIds)
            if ((entry.completedTaskIds?.contains(Double(task.id))))! {
               let index = entry.completedTaskIds?.index(of: Double(task.id))
               entry.completedTaskIds?.remove(at: index!)
            }
            if (entry.createdTaskIds?.contains(Double(task.id)))! {
               let index = entry.createdTaskIds?.index(of: Double(task.id))
               entry.createdTaskIds?.remove(at: index!)
            }
         }
         context.delete(task)
         (UIApplication.shared.delegate as! AppDelegate).saveContext()
         getData()
         tableView.reloadData()
      }
   }
   
   @available(iOS 11.0, *)
   func tableView(_ tableView: UITableView,
                  leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
   {
      
      let closeAction = UIContextualAction(style: .normal, title:  "Complete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
         success(true)
         let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         let groupFilter = self.groups[indexPath.section].name
         var cellTask: [Task] = self.tasks.filter { $0.group == groupFilter }
         
         let task = cellTask[indexPath.row]
         task.setValue("Complete", forKey: "resolution")
         task.setValue(NSDate(), forKey: "dateCompleted")
         
         self.addTaskToCompletedEntry(task: task)
         
         let requestedComponent: Set<Calendar.Component> = [ .month, .day, .hour, .minute, .second]
         let timeDifference = NSCalendar.current.dateComponents(requestedComponent, from: task.timeCreated! as Date, to: NSDate() as Date)

         if(timeDifference.minute! < 5) {
          //inform user no points added for rapid creation/completion
            let alert = UIAlertController(title: "Error", message: "This task was recently created, no points will be awarded for marking as complete. Next time plan ahead!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
         }
         else {
            self.User.pointScore += 1
            if(self.User.loggedIn) {
               Database.database().reference().child("users").child(self.User.uid!).child("pointScore").setValue(self.User.pointScore)
            }
         }
         do {
            try context.save()
            print("saved successfully")
         }
         catch {
            print("could not save")
         }
         self.getData()
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            tableView.reloadData()
         })
      })
      closeAction.image = UIImage(named: "tick")
      closeAction.backgroundColor = .purple
      return UISwipeActionsConfiguration(actions: [closeAction])
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      if(groups.count != 0) {
         let temp = groups[section].name
         return temp
      }
      return "Test"
   }
   
   @available(iOS 3.0, *)
   public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      //segue to tableview showing all completed and incompleted tasks for that day
      selectedIndexPath = indexPath;
      self.performSegue(withIdentifier: "editTaskSegue", sender: nil)
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "editTaskSegue" {
         let editVC: EditTaskVC = segue.destination as! EditTaskVC
         
         let groupFilter = self.groups[selectedIndexPath.section].name
         var cellTask: [Task] = self.tasks.filter { $0.group == groupFilter }
         let task = cellTask[selectedIndexPath.row]
         
         editVC.taskToEdit = task
         editVC.savedTaskText = task.name!
         editVC.groupLabelHolder = task.group!
         editVC.dueDateHolder = task.dueDate! as Date
         editVC.priorityControlHolder = Int(task.priority)
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }


}

