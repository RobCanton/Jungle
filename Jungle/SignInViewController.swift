//
//  SignInViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import NVActivityIndicatorView


class SignInViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var closeButton:UIButton!
    var loginButton:UIButton!
    var activityView:NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        loginButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.setTitle("Log In", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
        loginButton.center = view.center
        
        loginButton.layer.cornerRadius = loginButton.frame.height / 2
        loginButton.clipsToBounds = true
        loginButton.addTarget(self, action: #selector(handleSignin), for: .touchUpInside)
        
        view.addSubview(loginButton)
        
        emailField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        emailField.enablesReturnKeyAutomatically = true
        passwordField.enablesReturnKeyAutomatically = true
        
        setLoginButton(enabled: false)
        
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 36, height: 36), type: .ballBeat, color: UIColor.white, padding: 1.0)
        view.addSubview(activityView)
        
    }
    
    func textFieldChanged(_ target:UITextField) {
        switch target {
        case emailField:
            break
        case passwordField:
            break
        default:
            break
        }
        
        if let email = emailField.text,
            email != "",
            let password = passwordField.text,
            password != "" {
            setLoginButton(enabled: true)
        } else {
            setLoginButton(enabled: false)
        }
    }
    
    func setLoginButton(enabled:Bool) {
        if enabled {
            loginButton.backgroundColor = accentColor
            loginButton.isEnabled = true
        } else {
            loginButton.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
            loginButton.isEnabled = false
        }
    }
    
    func handleDismiss() {
        self.dismiss(animated: false, completion: nil)
    }
    
    func handleSignin() {
        guard let email = emailField.text else { return }
        guard let pass = passwordField.text else { return }
        closeButton.isEnabled = false
        setLoginButton(enabled: false)
        loginButton.setTitle("", for: .normal)
        activityView.startAnimating()
        
        Auth.auth().signIn(withEmail: email, password: pass, completion: { (user, error) in
            
            if error != nil && user == nil {
                self.reset()
                return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to sign in.")
            } else {
                self.dismiss(animated: false, completion: nil)
                return
            }
        })
    }
    
    func reset() {
        loginButton.setTitle("Log In", for: .normal)
        setLoginButton(enabled: true)
        closeButton.isEnabled = true
        self.activityView.stopAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            emailField.resignFirstResponder()
            passwordField.becomeFirstResponder()
            break
        case passwordField:
            handleSignin()
            break
        default:
            break
        }
        
        return true
    }
    
    
    
    
    
    
    
    func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        loginButton.center = CGPoint(x: view.center.x, y: view.frame.height - keyboardFrame.height - 16.0 - loginButton.frame.height / 2)
        activityView.center = loginButton.center
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    
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
