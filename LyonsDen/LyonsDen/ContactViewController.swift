//
//  ContactViewController.swift
//  LyonsDen
//
//  The ContactViewContrller will be used for controlling the contact screen.
//
//  Created by Inal Gotov on 2016-06-30.
//  Copyright © 2016 William Lyon Mackenize CI. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Contacts

class ContactViewController: UIViewController {
    static var displayToast = true
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet var navBar: UINavigationItem!
    var toast:ToastView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sidemenu swipeable
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if ContactViewController.displayToast {
            toast = ToastView(inView: self.view, withText: "Proposal Submitted!")
            self.view.addSubview(toast)
            ContactViewController.displayToast = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let toastView = toast {
            toastView.initiate()
        }
    }
    
    @IBAction func displayTeacherList(sender: UIButton) {
        PeopleList.listRef = FIRDatabase.database().referenceWithPath("users").child("teachers")
        PeopleList.title = "Teachers"
        performSegueWithIdentifier("TeacherListSegue", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // This is required for a successful unwind to this View Controller
    @IBAction func myUnwindAction (unwindSegue: UIStoryboardSegue) {
        
    }
    
    // for contacts
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                //let predicate = CNContact.predicateForContactsMatchingName(self.txtLastName.text!)
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
                var contacts = [CNContact]()
                var message: String!
            }
        }
        
        return true
    }
    

    @IBAction func hotlineSelected(sender: AnyObject) {
        let options = UIAlertController(title: "Emergency Hotline", message: "Who would you like to talk to?", preferredStyle: .ActionSheet)
        options.addAction(UIAlertAction(title: "Student Emergency Hotline", style: .Default, handler: { action in
            self.phoneCall(NSURL(string: "telprompt://1-800-668-6868")!) // kids help phone
        }))
        options.addAction(UIAlertAction(title: "Emergency Contact", style: .Default, handler: { action in
            // for now
            self.phoneCall(NSURL(string: "telprompt://647-300-9301")!) // rachels
        })) // set emergency contact from contacts in phone. save to NSDefaults. figure out how
        options.addAction(UIAlertAction(title: "WLMCI", style: .Default, handler: { action in
            self.phoneCall(NSURL(string: "telprompt://416-395-3330")!) // school's phone
        }))
        options.addAction(UIAlertAction(title: "911", style: .Default, handler: { action in
            self.phoneCall(NSURL(string: "telprompt://911")!) // obvious

        }))
        options.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(options, animated: true, completion: nil)
    }
    
    private func phoneCall (phoneNumber: NSURL) {
        if UIApplication.sharedApplication().canOpenURL(phoneNumber) {
            UIApplication.sharedApplication().openURL(phoneNumber)
        }
    }
}


class ToastView: UIView {
    var displayText:String
    
    override func drawRect(rect: CGRect) {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        label.font = label.font.fontWithSize(22)
        label.text = displayText
        label.sizeToFit()
        self.frame.size.width = label.frame.width + 16
        self.frame.size.height = label.frame.height + 16
        self.addSubview(label)
        label.frame.origin.x = 0
        label.frame.size.width = self.frame.size.width
//        label.center.x = self.frame.
        label.center.y = self.frame.size.height/2
        self.backgroundColor = UIColor(white: 0, alpha: 0.25)
        self.alpha = 0
        label.alpha = 0.7
    }
    
    func initiate () {
        UIView.animateWithDuration(0.1) { self.alpha = 1 }
        UIView.animateWithDuration(0.1, delay: 1.1, options: .AllowAnimatedContent, animations: { self.alpha = 0 }, completion: { (completed) in if completed { self.removeFromSuperview() } })
    }
    
    convenience init(inView view:UIView, withText text:String) {
        self.init(frame: CGRectZero, inView: view, withText: text)
    }
    
    init(frame: CGRect, inView view:UIView, withText text:String) {
        displayText = text
        super.init(frame: CGRectMake((view.center.x - (135/2)), (view.center.y - (45/2)), 135, 45))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}