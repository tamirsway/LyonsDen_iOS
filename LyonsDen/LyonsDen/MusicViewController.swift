//
//  MusicViewController.swift
//  LyonsDen
//
//  Created by Inal Gotov on 2016-07-06.
//  Copyright © 2016 William Lyon Mackenize CI. All rights reserved.
//

import UIKit

class MusicVIewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view title text, at the Navigation Bar
        self.title = "Propose Song for Radio"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    
}
