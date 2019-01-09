//
//  UserProfileTableViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 09/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit
import ProgressHUD

class UserProfileTableViewController: UITableViewController {

    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var callUserButton: UIButton!
    @IBOutlet weak var messageUserButton: UIButton!
    
    var user: FUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }

    @IBAction func callUser(_ sender: UIButton) {
    }
    
    @IBAction func messageUser(_ sender: UIButton) {
        
    }
    
    @IBAction func blockUser(_ sender: UIButton) {
        
        var currentBlockIds = FUser.currentUser()!.blockedUsers
        
        if currentBlockIds.contains(user!.objectId) {
            currentBlockIds.remove(at: currentBlockIds.index(of: user!.objectId)!)
        } else {
            currentBlockIds.append(user!.objectId)
        }
        ProgressHUD.show()
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: currentBlockIds]) { (error) in
            if error != nil {
                print("error updating user \(String(describing: error?.localizedDescription))")
                return
            }
            ProgressHUD.dismiss()
            self.updateBlockStatus()
        }
    }
    
    func setUpUI() {
        if user != nil {
            self.title = "Profile"
            
            fullName.text = user!.fullname
            phoneNumber.text = user!.phoneNumber
            updateBlockStatus()
            
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.profilePic.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    func updateBlockStatus() {
        if user!.objectId != FUser.currentId() {
            blockButton.isHidden = false
            callUserButton.isHidden = false
            messageUserButton.isHidden = false
        } else {
            blockButton.isHidden = true
            callUserButton.isHidden = true
            messageUserButton.isHidden = true
        }
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
            blockButton.setTitle("Unblock User", for: .normal)
        } else {
            blockButton.setTitle("Block User", for: .normal)
        }
    }
    
}
