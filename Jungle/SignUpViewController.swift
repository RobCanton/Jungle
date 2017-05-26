//
//  SignUpViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//



import Foundation
import UIKit
import Firebase
import ActiveLabel

class SignUpNameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstnameField: UITextField!
    
    @IBOutlet weak var lastnameField: UITextField!
    
    var closeButton:UIButton!
    var submitButton:UIButton!
    
    @IBOutlet weak var legal: ActiveLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstnameField.delegate = self
        lastnameField.delegate = self
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        submitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        submitButton.setTitleColor(UIColor.white, for: .normal)
        submitButton.setTitle("Sign Up & Accept", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
        submitButton.center = view.center
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        view.addSubview(submitButton)
        
        firstnameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        lastnameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        firstnameField.enablesReturnKeyAutomatically = true
        lastnameField.enablesReturnKeyAutomatically = true
        
        setLoginButton(enabled: false)
        
        let termsType = ActiveType.custom(pattern: "\\sTerms of Use\\b") //Regex that looks for "with"
        let privacyType = ActiveType.custom(pattern: "\\sPrivacy Policy\\b") //Regex that looks for "with"
        legal.enabledTypes = [termsType, privacyType]
        
        legal.customColor[termsType] = infoColor
        legal.customSelectedColor[termsType] = UIColor.darkGray
        
        legal.handleCustomTap(for: termsType) { element in
            print("Custom type tapped: \(element)")
            let web = WebViewController()
            web.title = "Terms of Use"
            web.urlString = "https://getlit.site/terms.html"
            let nav = UINavigationController(rootViewController: web)
            self.present(nav, animated: true, completion: nil)
        }
        
        legal.customColor[privacyType] = infoColor
        legal.customSelectedColor[privacyType] = UIColor.darkGray
        
        legal.handleCustomTap(for: privacyType) { element in
            print("Custom type tapped: \(element)")
            let web = WebViewController()
            web.title = "Privacy Policy"
            web.urlString = "https://getlit.site/privacypolicy.html"
            let nav = UINavigationController(rootViewController: web)
            self.present(nav, animated: true, completion: nil)
        }
        
        legal.text = "By tapping Sign Up & Accept, you accept the Terms of Use and Privacy Policy."
        
    }
    
    func textFieldChanged(_ target:UITextField) {
        switch target {
        case firstnameField:
            break
        case lastnameField:
            break
        default:
            break
        }
        
        if let firstname = firstnameField.text,
            firstname != "" {
            setLoginButton(enabled: true)
        } else {
            setLoginButton(enabled: false)
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
        guard let firstname = firstnameField.text, firstname != "" else { return }
        
        self.performSegue(withIdentifier: "toBirthday", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstnameField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        firstnameField.resignFirstResponder()
        lastnameField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstnameField:
            firstnameField.resignFirstResponder()
            firstnameField.becomeFirstResponder()
            break
        case firstnameField:
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
