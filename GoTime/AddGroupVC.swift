//
//  AddGroupVC.swift
//  GoTime
//
//  Created by Robert Mathews on 5/29/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import CoreData

protocol MyProtocol {
   func setGroupButton(groupButton: String)
   func setTextBack(taskSavedText: String)
}

class AddGroupVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
   
   var groups : [Group] = []
   var myProtocol: MyProtocol?
   var taskText: String = ""
   
   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var newGroupTextField: UITextField!
   
   var newTaskViewController: NewTaskViewController = NewTaskViewController()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      tableView.dataSource = self
      tableView.delegate = self
      newGroupTextField.delegate = self
      
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
   public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      if(newGroupTextField.hasText) {
         newGroupTextField.resignFirstResponder()
         let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         let group = Group(context: context)
         group.name = newGroupTextField.text
         (UIApplication.shared.delegate as! AppDelegate).saveContext()
         getData()
         tableView.reloadData()
         return true
      }
      return false
}
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return groups.count
   }
   
   @available(iOS 2.0, *)
   public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
      if (indexPath.row < groups.count) {
         let group = groups[indexPath.row]
         cell.textLabel?.text = group.name!
      }
      
      return cell;
   }
   
   @available(iOS 3.0, *)
   public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      myProtocol?.setGroupButton(groupButton: groups[indexPath.row].name!)
      myProtocol?.setTextBack(taskSavedText: self.taskText)
      //should run async
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            self.dismiss(animated: true, completion: nil)
      })
   }
   
   private func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      do {
         try groups = context.fetch(Group.fetchRequest())
         if (groups.count == 0) {
            initializeGroups()
         }
      }
      catch {
         print("Error: fetch failed")
      }
   }
   
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return "Groups"
   }
   
   private func initializeGroups() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      
      let group = Group(context: context)
      group.name = "None"
      (UIApplication.shared.delegate as! AppDelegate).saveContext()
      
      getData()
      tableView.reloadData()
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
}


