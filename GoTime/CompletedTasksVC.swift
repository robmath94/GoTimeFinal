//
//  CompletedTasksVC.swift
//  GoTime
//
//  Created by Robert Mathews on 5/29/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import CoreData

class CompletedTasksVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var tasks : [Task] = []
   var groups : [Group] = []
   var priorityType : [String] = ["⏬", "⬇️", "⏺", "⬆️", "⏫"]
   var userData: [UserData] = []
   var User: UserData = UserData()
   var entries:[Entry] = []
   
   @IBOutlet var pointScore: UILabel!
   @IBOutlet var tableView: UITableView!
   override func viewDidLoad() {
      super.viewDidLoad()
      tableView.dataSource = self
      tableView.delegate = self
      
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
      self.tabBarController?.navigationItem.title = "Completed Tasks"
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
      cell.taskLabel?.textColor = UIColor.darkGray
      return cell;
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      let request: NSFetchRequest<Task> = Task.fetchRequest()
      let filterString = "Complete"
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
      }
      catch {
         print("Error: fetch failed")
      }
      User = userData.first!
      pointScore.text = String(describing: User.pointScore)
   }
   
   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return 25;
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
         
         context.delete(task)
         
         for entry in entries {
            if (entry.completedTaskIds?.contains(Double(task.id)))! {
               let index = entry.completedTaskIds?.index(of: Double(task.id))
               entry.completedTaskIds?.remove(at: index!)
            }
            if (entry.createdTaskIds?.contains(Double(task.id)))! {
               let index = entry.createdTaskIds?.index(of: Double(task.id))
               entry.createdTaskIds?.remove(at: index!)
            }
         }
         
         (UIApplication.shared.delegate as! AppDelegate).saveContext()
         getData()
         tableView.reloadData()
      }
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      if(groups.count != 0) {
         let temp = groups[section].name
         return temp
      }
      return "Test"
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
}


