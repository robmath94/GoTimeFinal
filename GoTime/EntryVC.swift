//
//  EntryVC.swift
//  GoTime
//
//  Created by Robert Mathews on 5/29/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import CoreData

class EntryVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var tasks : [Task] = []
   var groups : [Group] = []
   var priorityType : [String] = ["⏬", "⬇️", "⏺", "⬆️", "⏫"]
   var userData: [UserData] = []
   var User: UserData = UserData()
   var entryDate:NSDate = NSDate()
   
   @IBOutlet weak var dateHeader: UILabel!
   @IBOutlet weak var tableView: UITableView!
   
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
      request.predicate = NSPredicate(format: "dateCreated == %@", entryDate)
      do {
         tasks = try context.fetch(request)
         groups = try context.fetch(Group.fetchRequest())
         userData = try context.fetch(UserData.fetchRequest())
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
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM dd yyyy"
      dateHeader.text = formatter.string(from: tasks[0].dateCreated! as Date)
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
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
      if let adpostVC = segue.destination as? EntryVC {
         let popPC = adpostVC.popoverPresentationController
         popPC?.delegate = self
      }
   }
}
   
   extension EntryVC: UIPopoverPresentationControllerDelegate {
      func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
         return UIModalPresentationStyle.fullScreen
      }
      
      func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
         return UINavigationController(rootViewController: controller.presentedViewController)
      }
   }


