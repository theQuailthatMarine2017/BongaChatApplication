//
//  SettingTableViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 05/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        
        tableView.rowHeight = 60
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    @IBAction func logOut(_ sender: UIButton) {
        
        FUser.logOutCurrentUser { (success) in
            
            if success {
               self.showLoginView()
            }
        }
    }
    
    func showLoginView() {
    
       let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        
        self.present(mainView, animated: true, completion: nil)
    }
}
