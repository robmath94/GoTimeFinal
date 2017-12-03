//
//  FeedVC.swift
//  GoTime
//
//  Created by Robert Mathews on 9/16/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class DataModel {
   var username: String?
   var pointScore: Int?
   
   init(username:String?, pointScore:Int?) {
      self.username = username
      self.pointScore = pointScore
   }
}

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
   @IBOutlet weak var tableView: UITableView!

   var ref = Database.database().reference()
   var data:[DataSnapshot] = []
   
   var userList = [DataModel]()
   var userDAO: UserData = UserData()
   
   override func viewWillAppear(_ animated: Bool) {
      self.tabBarController?.navigationItem.title = "Leaderboards"
      tableView.reloadData()
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      do {
         userDAO = try context.fetch(UserData.fetchRequest()).first!
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
         })
      }
      catch {
         print("Error: fetch failed")
      }
   }
   
   @IBAction func logoutButtonPressed(_ sender: Any) {
      if Auth.auth().currentUser != nil {
         do{
            userDAO.uid = nil
            userDAO.loggedIn = false
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            try? Auth.auth().signOut()
            
            navigationController?.popViewController(animated: true)
         }
         catch let error as NSError {
            print(error.localizedDescription)
         }
      }
   }
   override func viewDidLoad() {
      super.viewDidLoad()
      self.tableView.delegate = self
      self.tableView.dataSource = self
      getData()
      let background = CAGradientLayer().setBackground()
      background.frame = self.view.bounds
      self.view.layer.insertSublayer(background, at: 0)

      ref.child("users").observe(DataEventType.value, with: { (snapshot) in
         
         self.userList.removeAll()
         for users in snapshot.children.allObjects as![DataSnapshot] {
            let dataObject = users.value as? [String: AnyObject]
            let username = dataObject?["username"]
            let pointScore = dataObject?["pointScore"]
            
            let user = DataModel(username: username as! String?, pointScore: pointScore as! Int)
            self.userList.append(user)
            if(self.userDAO.name == username as! String) {
               self.userDAO.setValue(pointScore as! Int, forKey: "pointScore")
               (UIApplication.shared.delegate as! AppDelegate).saveContext()
            }
         }
         self.userList = self.userList.sorted(by: { $0.pointScore! > $1.pointScore! })
         self.tableView.reloadData()
         })
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return userList.count
   }
   
   @available(iOS 2.0, *)
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskTableViewCell
      
      let user = userList[indexPath.row]
      cell.taskLabel?.text = user.username!
      cell.priorityLabel?.text = String(describing: user.pointScore!)
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return "Username                                           GoPoints"
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
   {
      if (editingStyle == UITableViewCellEditingStyle.delete)
      {
         //list.remove(at: indexPath.row)
         tableView.reloadData()
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
}
