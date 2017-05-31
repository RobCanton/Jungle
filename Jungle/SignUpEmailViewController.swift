//
//  SignUpEmailViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import Foundation
import UIKit
import Firebase

class SignUpEmailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailBorder: UIView!
    
    var closeButton:UIButton!
    var submitButton:UIButton!
    
    fileprivate var email:String?
    
    weak var newUser:NewUser?
    
    var bottomGradientView:UIView!
    
    deinit {
        print("Deinit >> SignUpEmailViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        submitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        submitButton.setTitleColor(UIColor.white, for: .normal)
        submitButton.setTitle("Continue", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
        submitButton.center = view.center
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        view.addSubview(submitButton)
        
        emailField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emailField.enablesReturnKeyAutomatically = true
        
        setLoginButton(enabled: false)
        
        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 64))
        self.view.insertSubview(gradientView, aboveSubview: scrollView)
        
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.colors = [
            UIColor(white: 1.0, alpha: 1.0).cgColor,
            UIColor(white: 1.0, alpha: 0.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradientView.layer.insertSublayer(gradient, at: 0)
        
        bottomGradientView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 64))
        self.view.insertSubview(bottomGradientView, aboveSubview: scrollView)
        
        let gradient2 = CAGradientLayer()
        gradient2.frame = gradientView.bounds
        gradient2.colors = [
            UIColor(white: 1.0, alpha: 0.0).cgColor,
            UIColor(white: 1.0, alpha: 1.0).cgColor
        ]
        gradient2.locations = [0.0, 1.0]
        gradient2.startPoint = CGPoint(x: 0, y: 0)
        gradient2.endPoint = CGPoint(x: 0, y: 1)
        bottomGradientView.layer.insertSublayer(gradient2, at: 0)
        
    }
    
    func textFieldChanged(_ target:UITextField) {
        switch target {
        case emailField:
            break
        default:
            break
        }
        validateForm()
    }
    
    func validateForm() {
        email = nil
        setLoginButton(enabled: false)
        
        if let email = emailField.text, email != "", isValidEmail(testStr: email) {
            self.email = email
            setLoginButton(enabled: true)
        }
        
    }
    
    
    func setLoginButton(enabled:Bool) {
        if enabled {
            submitButton.backgroundColor = accentColor
            submitButton.isEnabled = true
        } else {
            submitButton.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
            submitButton.isEnabled = false
        }
    }
    
    func handleDismiss() {
        self.dismiss(animated: false, completion: nil)
    }
    
    func handleSubmit() {
        guard let email = self.email else { return }
        
        closeButton.isEnabled = false
        setLoginButton(enabled: false)
        
        newUser?.email = email
        self.performSegue(withIdentifier: "toProfilePicture", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toProfilePicture" {
            let dest = segue.destination as! SignUpProfilePictureViewController
            dest.newUser = newUser
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        validateForm()
        emailField.becomeFirstResponder()
        closeButton.isEnabled = true
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            emailField.resignFirstResponder()
            handleSubmit()
            break
        default:
            break
        }
        
        return true
    }
    
    func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        submitButton.center = CGPoint(x: view.center.x, y: view.frame.height - keyboardFrame.height - 16.0 - submitButton.frame.height / 2)
        bottomGradientView.center = CGPoint(x: view.center.x, y: view.frame.height - keyboardFrame.height - bottomGradientView.frame.height / 2)
    }
    
    
    func keyboardWillDisappear(notification: NSNotification){
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

