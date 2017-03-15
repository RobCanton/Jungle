//
//  LoginViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase


class LoginViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            if error == nil {
                self.performSegue(withIdentifier: "login", sender: self)
            } else {
                print(error!.localizedDescription)
            }
            
        }
        
    }
}
