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

    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var createAccountButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.borderWidth = 2.0
        loginButton.layer.borderColor = UIColor.black.cgColor
        
        createAccountButton.layer.borderWidth = 2.0
        createAccountButton.layer.borderColor = UIColor.black.cgColor

//        FIRAuth.auth()?.signInAnonymously() { (user, error) in
//            if error == nil {
//                self.performSegue(withIdentifier: "login", sender: self)
//            } else {
//                print(error!.localizedDescription)
//            }
//            
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = FIRAuth.auth()?.currentUser {
            UserService.getUser(user.uid, completion: { user in
                if user != nil {
                    mainStore.dispatch(UserIsAuthenticated(user: user!))
                    Listeners.startListeningToFollowers()
                    Listeners.startListeningToFollowing()
                    Listeners.startListeningToConversations()
                    self.performSegue(withIdentifier: "login", sender: self)
                }
            })
            
        }
    }
    
    @IBAction func handleCreateAccount(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toCreateAccount", sender: self)
    }
}
