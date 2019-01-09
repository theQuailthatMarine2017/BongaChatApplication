//
//  ViewController.swift
//  Bonga
//
//  Created by RastaOnAMission on 01/10/2018.
//  Copyright © 2018 ronyquail. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func goRegisterLogin(_ sender: UIButton) {
        performSegue(withIdentifier: "registerLogin", sender: self)
    }
    
}

