//
//  SignUpController.swift
//  SQLServerTest
//
//  Created by Xiaoyu Chen on 7/9/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import UIKit

class SignUpController: UIViewController, SQLClientDelegate, UITextFieldDelegate {
    var myClient = SQLClient.sharedInstance()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirm: UITextField!
    @IBOutlet weak var submit: UIButton!
    override func viewDidLoad() {
        myClient.delegate = self
        self.username.returnKeyType = UIReturnKeyType.Done
        self.password.returnKeyType = UIReturnKeyType.Done
        self.confirm.returnKeyType = UIReturnKeyType.Done
        self.username.delegate = self
        self.password.delegate = self
        self.confirm.delegate = self
        self.password.clearsOnBeginEditing = true
        self.confirm.clearsOnBeginEditing = true
        self.password.secureTextEntry = true
        self.confirm.secureTextEntry = true
    }
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    @IBAction func submit(sender: AnyObject) {
        if (username.text == nil || password.text == nil || confirm.text == nil) {
            alert("Cannot submit", content: "Must fill in all fields", button: "OK")
            return
        }
        if (password.text != confirm.text) {
            alert("Cannot submit", content: "Password is not matched", button: "OK")
            return
        }
        var existed: Bool = false
        
        self.myClient.connect("10.60.107.54:50539", username: "Tj_iDriver", password: "tjrdlabserver@1234", database: "Tj_iDrive") {success in
            if (success) {
                
                self.myClient.execute("SELECT * FROM driver WHERE d_username='\(self.username.text)'") {result in
                    println(5)
                    for table in result {
                        if table.count > 0 {
                            existed = true
                        }
                    }
                    self.myClient.disconnect()
                    if (!existed) {
                        self.myClient.connect("10.60.107.54:50539", username: "Tj_iDriver", password: "tjrdlabserver@1234", database: "Tj_iDrive") {success in
                            if (success) {
                                
                                self.myClient.execute("INSERT INTO driver VALUES('\(self.username.text)', '\(self.password.text)')") {result in
                                    self.alert("Success", content: "You have successfully signed up", button: "OK")
                                    self.myClient.disconnect()
                                }
                            }
                        }
                    }
                    else {
                        self.alert("Invalid sign up", content: "username already existed", button: "Cancel")
                    }
                }
            }
        }

    }
    
    func alert(title: String, content: String, button: String) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: button, style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func error(error: String!, code: Int32, severity: Int32) {
        NSLog("Error %d: %s (severity %d)", code, error,severity)
    }
}
