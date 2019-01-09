//
//  FinishRegistrationViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 03/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import ProgressHUD
import ChameleonFramework

class FinishRegistrationViewController: UIViewController {
    

    @IBOutlet weak var profileAvatar: UIImageView!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    
    var email: String!
    var password: String!
    var profilePic: UIImage?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
     
        

        // Do any additional setup after loading the view.
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        
        clearText()
        dissmissKeyboard()
    }
    
    
    
    @IBAction func completeReg(_ sender: UIButton) {
        dissmissKeyboard()


            if firstName.text != "" && lastName.text != "" && country.text != "" && city.text != "" && phoneNumber.text != "" {
                
                ProgressHUD.show("Completing Registration and Creating Your Profile...")
                FUser.registerUserWith(email: email!, password: password!, firstName: firstName.text!, lastName: lastName.text!) { (error) in
    
                    if error != nil {
                        ProgressHUD.showError(error?.localizedDescription, interaction: true)
                        
                        return
                    } else {
                        
                        self.registerUser()
                       
                    }
                }
            }
    }

    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        dissmissKeyboard()
        
    }
    
    func dissmissKeyboard() {
        self.view.endEditing(false)
        
    }
    
    func clearText() {
        firstName.text = ""
        lastName.text = ""
        country.text = ""
        city.text = ""
        phoneNumber.text = ""
        
    }
    
    func registerUser() {

        let fullName = firstName.text! + " " + lastName.text!

        var tempDic: Dictionary = [kFIRSTNAME: firstName.text!, kLASTNAME: lastName.text!, kFULLNAME: fullName, kCOUNTRY: country.text!, kCITY: city.text!, kPHONE: phoneNumber.text!] as [String: Any]

        if profilePic == nil {


            imageFromInitials(firstName: firstName.text!, lastName: lastName.text!) { (avatarInitials) in
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.7)
                let avatar = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

                tempDic[kAVATAR] = avatar

                self.finishRegistration(withValues: tempDic)
                // finish registration
            }
        } else {

            let avatarData = profilePic?.jpegData(compressionQuality: 0.7)
            let avatar = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

            tempDic[kAVATAR] = avatar

        }
    }

    func finishRegistration(withValues: [String: Any]) {
        ProgressHUD.dismiss()
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            
            DispatchQueue.main.async {
                ProgressHUD.showSuccess("Successful", interaction: true)
            }
            self.goToApp()
            return
            
        }

    }
    
    func goToApp() {
        ProgressHUD.dismiss()
        dissmissKeyboard()
        clearText()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
}
