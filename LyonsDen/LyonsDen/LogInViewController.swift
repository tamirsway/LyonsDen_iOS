//
//  LogInScreenController.swift
//  LyonsDen
//
//  Created by Tamir Arnesty on 2016-07-09.
//  Copyright © 2016 William Lyon Mackenize CI. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

// TODO: AUTO_LOGIN PERFORMS TWICE FROM TIME TO TIME< WHICH CAUSES A THROW BACK INTO HOME SCREEN, PUT AUTO_LOG IN A DIFFERENT PLACE

class LogInViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var userNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var segmentedController: UISegmentedControl!
    @IBOutlet var signUpKeyField: UITextField!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomDenConstraint: NSLayoutConstraint!
    @IBOutlet var passwordFieldConstraint: NSLayoutConstraint!
    @IBOutlet weak var logInButton: UIButton!
    
    var entranceOption:Int!
    var password = ""
    var username = ""
    let signUpKey = "MacLyonsRule"  // idk, this should be something symbolic or patriotic... or secretive
    
    @IBAction func optionSwitched(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: // sign up
            entranceOption = 0
            print(entranceOption)
            self.view.layoutIfNeeded()
            
            UIView.animateWithDuration(0.5, animations: {
                self.signUpKeyField.alpha = 1
                self.logInButton.frame.origin.y += self.signUpKeyField.frame.height/2
                self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    self.signUpKeyField.hidden = false // textfield shows up
            })
        case 1: // log in
            entranceOption = 1
            print(entranceOption)
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.5, animations: {
                self.signUpKeyField.alpha = 0
                self.logInButton.frame.origin.y -= self.signUpKeyField.frame.height/2
                self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    self.signUpKeyField.hidden = true // textfield disappears
            })
        default:
            break
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [UIColor.whiteColor().CGColor, accentColor.CGColor]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
        self.userNameField.delegate = self
        self.passwordField.delegate = self
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func buttonPressed(sender: AnyObject) {
        self.password = passwordField.text!
        self.username = userNameField.text!
    
        if (passwordField.text?.isEmpty)! || (userNameField.text?.isEmpty)! {
            (UIApplication.sharedApplication().delegate as! AppDelegate).displayError("Missing Information", errorMsg: "Please fill in all the requirements.")
            return
        }
        
        if entranceOption == 0 {
            if signUpKeyField.text == signUpKey {
                FIRAuth.auth()?.createUserWithEmail(self.username, password: self.password, completion: {(user, error) in
                    if error != nil {
                        if let code = FIRAuthErrorCode(rawValue: error!.code) {
                            switch code {
                            case .ErrorCodeEmailAlreadyInUse: // user exists
                                (UIApplication.sharedApplication().delegate as! AppDelegate).displayError("Sorry!", errorMsg: "This email is already in use. Please log in, or use another email to sign up.")
                            case .ErrorCodeInvalidEmail: // self explanatory
                                (UIApplication.sharedApplication().delegate as! AppDelegate).displayError("Invalid Email", errorMsg: "Please make sure your email is typed in correctly.")
                            default:
                                break
                            }
                        }
                    } else {
                        if user != nil {
                            //Log in succesfull
                            NSUserDefaults.standardUserDefaults().setValue(self.password, forKey: "Pass")   // Memorize the password for next login
                            NSUserDefaults.standardUserDefaults().setValue(self.username, forKey: "uID")    // Memorize the username for next login
                            self.performSegueWithIdentifier("LogInSuccess", sender: self)
                        }
                    }
                }) // createUserWithEmail close
            } else {
                (UIApplication.sharedApplication().delegate as! AppDelegate).displayError("Incorrect Sign Up Key", errorMsg: "Please try again.")
            } // first if close
        } else if entranceOption == 1 {
            // Authentication
            FIRAuth.auth()?.signInWithEmail(self.username, password: self.password, completion: { (user, error) in
                if error != nil {
                    if let code = FIRAuthErrorCode(rawValue: error!.code) {
                        switch code {
                        case .ErrorCodeWrongPassword: // wrong password
                            (UIApplication.sharedApplication().delegate as! AppDelegate).displayError("Invalid Password", errorMsg: "The password you entered is incorrect. Please try again.")
                        default:
                            break
                        }
                    }
                } else {
                    if user != nil {
                        //Log in succesfull
                        NSUserDefaults.standardUserDefaults().setValue(self.password, forKey: "Pass")   // Memorize the password for next login
                        NSUserDefaults.standardUserDefaults().setValue(self.username, forKey: "uID")    // Memorize the username for next login
                        self.performSegueWithIdentifier("LogInSuccess", sender: self)
                    }
                }
            }) // signInWIthEmail close
        } else {
            print("Something is very wrong...")
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}