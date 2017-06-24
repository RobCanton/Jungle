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
import NVActivityIndicatorView

class FirstViewController:UIViewController {
    
    @IBOutlet weak var viewBackdrop: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewBackdrop.layer.cornerRadius = 16.0
        viewBackdrop.clipsToBounds = true
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
}

class FirstAuthViewController: FirstViewController {
    
    var activityView:NVActivityIndicatorView!
    
    override func viewDidLoad() {
         super.viewDidLoad()
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .ballBeat, color: UIColor.white, padding: 1.0)
        activityView.center = CGPoint(x: view.center.x, y: view.frame.height - 80 - 20.0)
        view.addSubview(activityView)
        
        activityView.startAnimating()
    }
    
    var authFetched = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = Auth.auth().currentUser {
            
            UserService.getUser(user.uid, completion: { user in
                self.authFetched = true
                if user != nil {
                    mainStore.dispatch(UserIsAuthenticated(user: user!))
                    UserService.sendFCMToken()
                    Listeners.startListeningToFollowers()
                    Listeners.startListeningToFollowing()
                    Listeners.startListeningToViewed()
                    Listeners.startListeningToSettings()
                    self.performSegue(withIdentifier: "login", sender: self)
                } else {
                    self.performSegue(withIdentifier: "toLoginScreen", sender: self)
                }
            })
        } else {
            authFetched = true
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if authFetched && Auth.auth().currentUser == nil {
            self.performSegue(withIdentifier: "toLoginScreen", sender: self)
        }
        
        
    }
}

class LoginViewController: UIViewController, UITextFieldDelegate {

    var gradientView:UIView!
    var gradient:CAGradientLayer?
    
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var signupButton: UIButton!
    
    
    var activityView:NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Activity view */
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .ballBeat, color: UIColor.white, padding: 1.0)
        activityView.center = CGPoint(x: view.center.x, y: view.frame.height - 80 - 20.0)
        view.addSubview(activityView)
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = Auth.auth().currentUser {
            isLoading(true)
            UserService.getUser(user.uid, completion: { user in
                self.isLoading(false)
                if user != nil {
                    mainStore.dispatch(UserIsAuthenticated(user: user!))
                    UserService.sendFCMToken()
                    Listeners.startListeningToFollowers()
                    Listeners.startListeningToFollowing()
                    Listeners.startListeningToViewed()
                    Listeners.startListeningToSettings()
                    //Listeners.startListeningForForcedRefresh()
                    self.performSegue(withIdentifier: "login", sender: self)
                }
            })
        } else {
            isLoading(false)
        }
    }

    func isLoading(_ loading:Bool) {
        if loading {
            activityView.startAnimating()
            loginButton.isHidden = true
            loginButton.isEnabled = false
            signupButton.isHidden = true
            signupButton.isEnabled = false
        } else {
            activityView.stopAnimating()
            loginButton.isHidden = false
            loginButton.isEnabled = true
            signupButton.isHidden = false
            signupButton.isEnabled = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override var prefersStatusBarHidden: Bool
        {
        get {
            return true
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    
}

class whoa: UIViewController, UITextFieldDelegate {
    
    var gradientView:UIView!
    var gradient:CAGradientLayer?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signinButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        gradientView = UIView(frame: view.bounds)
//        self.view.insertSubview(gradientView, at: 0)
//        gradientView.backgroundColor = UIColor.white
//        
//        self.gradient?.removeFromSuperlayer()
//        self.gradient = CAGradientLayer()
//        self.gradient!.frame = self.gradientView.bounds
//        self.gradient!.colors = [
//            lightAccentColor.cgColor,
//            darkAccentColor.cgColor
//        ]
//        self.gradient!.locations = [0.0, 1.0]
//        self.gradient!.startPoint = CGPoint(x: 0, y: 0)
//        self.gradient!.endPoint = CGPoint(x: 0, y: 1)
//        self.gradientView.layer.insertSublayer(self.gradient!, at: 0)
        
        emailTextField.layer.cornerRadius = 8.0
        emailTextField.clipsToBounds = true
        emailTextField.delegate = self
        
        passwordTextField.layer.cornerRadius = 8.0
        passwordTextField.clipsToBounds = true
        passwordTextField.delegate = self
        
        signinButton.layer.cornerRadius = 8.0
        signinButton.clipsToBounds = true
        
    }
    
    @IBAction func handleSignin(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let pass = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: pass, completion: { (user, error) in
            if error != nil && user == nil {
                print("Error signing in to accoutn")
                return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to sign in.")
            } else {
                self.dismiss(animated: true, completion: nil)
                return
            }
        })
    }
    
    @IBAction func handleDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override var prefersStatusBarHidden: Bool
        {
        get {
            return true
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }

    
}


class InsetTextField: UITextField {
    
    // placeholder position
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10 , dy: 0)
    }
    
    // text position
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10 , dy: 0)
    }

}

