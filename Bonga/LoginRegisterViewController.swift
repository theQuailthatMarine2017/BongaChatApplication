//
//  LoginRegisterViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 11/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import ProgressHUD

class LoginRegisterViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    @IBOutlet weak var loginEmailField: UITextField!
    @IBOutlet weak var loginPasswordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        self.view.frame.origin.y -= 150
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y += 150
    }
    
    @IBAction func registerUser(_ sender: UIButton) {
        
        if emailField.text != "" && passwordField.text != "" && confirmPasswordField.text != "" && passwordField.text! == confirmPasswordField.text! {
            
            ProgressHUD.dismiss()
            performSegue(withIdentifier: "registerUser", sender: self)
            clearTextField()
            
        } else {
            if emailField.text == "" && passwordField.text == "" && confirmPasswordField.text == "" {
                ProgressHUD.showError("Email and Password fields cannot be left blank")
                dissmissKeyboard()
                clearTextField()
            } else if emailField.text != "" && passwordField.text != confirmPasswordField.text {
                ProgressHUD.showError("Passwords do not match.")
                dissmissKeyboard()
                clearTextField()
            } else {
                ProgressHUD.showError("Unknown Error. Please check your internet connection or check you typed a valid Email and Password")
                dissmissKeyboard()
                clearTextField()
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "registerUser" {
            
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = emailField.text!
            vc.password = passwordField.text!
        }
    }
    
    @IBAction func loginUser(_ sender: UIButton) {
        
        if loginEmailField.text != "" && loginPasswordField.text != "" {
            
            loginUser()
            clearTextField()
        } else {
            if loginEmailField.text == "" && loginPasswordField.text == "" {
                ProgressHUD.showError("Email and Password fields cannot be left blank")
                dissmissKeyboard()
                clearTextField()
            } else {
                ProgressHUD.showError("Unknown Error. Please check your internet connection or check you typed a valid Email and Password")
                dissmissKeyboard()
                clearTextField()
            }
        }
        
    }
   
    @IBAction func backgroundPressed(_ sender: UITapGestureRecognizer) {
        dissmissKeyboard()
        
    }
    
    func dissmissKeyboard() {
        self.view.endEditing(false)
        
    }
    
    func loginUser() {
        ProgressHUD.show("Logging You In...")
        FUser.loginUserWith(email: loginEmailField.text!, password: loginPasswordField.text!) { (error) in
            if error != nil {
                ProgressHUD.showError(error?.localizedDescription, interaction: true)
                return
            } else {
                self.goToApp()
            }
        }
    }
    
    
//    func register() {
//
//    }
    
    func clearTextField() {
        emailField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        loginEmailField.text = ""
        loginPasswordField.text = ""
        
    }
    
    func goToApp() {
        ProgressHUD.dismiss()
        dissmissKeyboard()
        clearTextField()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
    }
    
}
