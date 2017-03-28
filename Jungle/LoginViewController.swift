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

    var gradientView:UIView!
    var gradient:CAGradientLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientView = UIView(frame: view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        gradientView.backgroundColor = UIColor.white
        
        self.gradient?.removeFromSuperlayer()
        self.gradient = CAGradientLayer()
        self.gradient!.frame = self.gradientView.bounds
        self.gradient!.colors = [
            UIColor(red: 220/255, green: 227/255, blue: 91/255, alpha: 1.0).cgColor,
            UIColor(red: 69/255, green: 182/255, blue: 73/255, alpha: 1.0).cgColor
        ]
        self.gradient!.locations = [0.0, 1.0]
        self.gradient!.startPoint = CGPoint(x: 0, y: 0)
        self.gradient!.endPoint = CGPoint(x: 0, y: 1)
        self.gradientView.layer.insertSublayer(self.gradient!, at: 0)

        
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
