//
//  SignInVC.swift
//  GoTime
//
//  Created by Robert Mathews on 5/22/17.
//  Copyright © 2017 Robert Mathews. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class SignInVC: UIViewController, UITextFieldDelegate {
   
   
   
   @IBOutlet weak var signInSelector: UISegmentedControl!
   @IBOutlet weak var signInLabel: UILabel!
   
   @IBOutlet weak var emailTextField: UITextField!
   @IBOutlet weak var passwordTextField: UITextField!
   @IBOutlet weak var usernameTextField: UITextField!
   
   @IBOutlet weak var signInButton: UIButton!
   @IBOutlet weak var confirmLabel: UILabel!
   @IBOutlet weak var passwordLabel: UILabel!
   @IBOutlet weak var usernameLabel: UILabel!
   
   @IBOutlet weak var confirmPasswordField: UITextField!
   var isSignIn:Bool = true
   
   var userData:[UserData] = []
   var userDAO: UserData = UserData()
   var userUid:String!
   
   @IBAction func signInSelectorChanged(_ sender: UISegmentedControl) {
      //button pressed, flip bool
      isSignIn = !isSignIn
      
      //clear the textFields
      usernameTextField.text = ""
      emailTextField.text = ""
      passwordTextField.text = ""
      confirmPasswordField.text = ""
      
      if isSignIn {
         signInLabel.text = "Sign In"
         signInButton.setTitle("Sign In", for: .normal)
         confirmLabel.isHidden = true
         passwordLabel.isHidden = true
         confirmPasswordField.isHidden = true
         usernameLabel.isHidden = true
         usernameTextField.isHidden = true
         signInButton.center.y += 150
         
      }
      else {
         signInLabel.text = "Register"
         signInButton.setTitle("Register", for: .normal)
         confirmLabel.isHidden = false
         passwordLabel.isHidden = false
         confirmPasswordField.isHidden = false
         usernameLabel.isHidden = false
         usernameTextField.isHidden = false
         signInButton.center.y -= 150
      }
   }
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      self.view.endEditing(true)
      return false
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      let background = CAGradientLayer().setBackground()
      background.frame = self.view.bounds
      self.view.layer.insertSublayer(background, at: 0)
      
      self.confirmPasswordField.delegate = self
      self.emailTextField.delegate = self
      self.passwordTextField.delegate = self
      signInButton.center.y += 150
      
      getData()
      
      let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
      //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
      //tap.cancelsTouchesInView = false
      view.addGestureRecognizer(tap)
      // Do any additional setup after loading the view, typically from a nib.
   }
   
   func getData() {
      let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
      
      do {
         userData = try context.fetch(UserData.fetchRequest())
         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
         })
      }
      catch {
         print("Error: fetch failed")
      }
      userDAO = userData.first!
   }
   
   func dismissKeyboard() {
      //Causes the view (or one of its embedded text fields) to resign the first responder status.
      view.endEditing(true)
   }
   
   override func viewWillAppear(_ animated: Bool) {
      self.tabBarController?.navigationItem.title = "Sign In"
   }
   
   override func viewDidAppear(_ animated: Bool) {
      getData()
      if(userDAO.loggedIn) {
        performSegue(withIdentifier: "goToFeed", sender: nil)
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   func setUpUser() {
      let userData = [
         "username": userDAO.name!,
         "pointScore": userDAO.pointScore
         ] as [String : Any]
      let setLocation = Database.database().reference().child("users").child(userUid)
      setLocation.setValue(userData)
   }
   
   
   @IBAction func signInButtonPressed(_ sender: UIButton) {
      //Form validaiton on email and password
      if let email = emailTextField.text, let pass = passwordTextField.text {
         if isSignIn {
            Auth.auth().signIn(withEmail: email, password: pass, completion: { (user, error) in
               if let user = user {
                  //user found, load feed
                  self.userUid = user.uid
                  self.userDAO.uid = user.uid
                  self.userDAO.loggedIn = true
                  (UIApplication.shared.delegate as! AppDelegate).saveContext()
                  self.performSegue(withIdentifier: "goToFeed", sender: self)
               }
               else {
                  print(error.debugDescription)
                  let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                  alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                  self.present(alert, animated: true, completion: nil)
               }
            })
         }
         else {
            //check passwords match
            if(passwordTextField.text == confirmPasswordField.text) {
               Auth.auth().createUser(withEmail: email, password: pass, completion: { (user, error) in
                  if let user = user {
                     //user created go to feed
                     self.userUid = user.uid
                     self.userDAO.loggedIn = true
                     self.userDAO.uid = user.uid
                     self.userDAO.name = self.usernameTextField.text
                     (UIApplication.shared.delegate as! AppDelegate).saveContext()
                     self.setUpUser()
                     self.performSegue(withIdentifier: "goToFeed", sender: self)
                  }
                  else {
                     //could not create user for some reason, throw error (user already exists, not a valid email, lots could go wrong?)
                     print(error.debugDescription)
                     let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                     alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                     self.present(alert, animated: true, completion: nil)
                  }
               })
            }
            else {
               //password and confirmation password do not match
               
            }
         }
         
      }
      
   }
   
}

