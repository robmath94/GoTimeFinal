//
//  SecondViewController.swift
//  GoTime
//
//  Created by Robert Mathews on 5/29/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import CoreData

class JournalVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   var tasks : [Task] = []
   var groups : [Group] = []
   var userData: UserData = UserData()
   var entries: [Entry] = []
   
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
      self.tabBarController?.navigationItem.title = "Journal"
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return entries.count
   }
   
   
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskTableViewCell
      let entry = entries[indexPath.row]
      let formatter = DateFormatter()
      
      formatter.dateFormat = "dd-MMM-yyyy"
      let dateString = formatter.string(from: entry.entryDate! as Date)
      cell.taskLabel?.text = dateString
      let completedString = entry.completedTaskIds?.count == nil ? 0 : entry.completedTaskIds!.count
      
      cell.priorityLabel!.text = String(describing: entry.createdTaskIds!.count) + "/" + String(describing: completedString)
      
      return cell
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      do {
         //tasks = try context.fetch(request)
          groups = try context.fetch(Group.fetchRequest())
          userData = (try context.fetch(UserData.fetchRequest()).first)!
         entries = try context.fetch(Entry.fetchRequest()).reversed()
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
         })
         //pointScore.text = String(userData.pointScore)
         if (groups.count == 0) {
            //initializeGroups()
         }
      }
      catch {
         print("Error: fetch failed")
      }
   }
   
   @available(iOS 3.0, *)
   public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      //segue to tableview showing all completed and incompleted tasks for that day
      self.performSegue(withIdentifier: "showEntrySegue", sender: nil)
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return "Journal Entries              Created/Completed"
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if  segue.identifier == "showEntrySegue",
         let destination = segue.destination as? EntryVC,
         let entryIndex = tableView.indexPathForSelectedRow?.row
      {
         destination.entryDate = entries[entryIndex].entryDate!
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
}

