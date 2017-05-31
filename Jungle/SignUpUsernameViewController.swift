
//
//  Created by Robert Canton on 2017-05-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

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

enum SignUpButtonState {
    case unset, none, valid, invalid
}

class SignUpUsernameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var check: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var usernameBorder: UIView!
    
    var closeButton:UIButton!
    var submitButton:UIButton!
    
    weak var newUser:NewUser?
    
    var bottomGradientView:UIView!
    
    deinit {
        print("Deinit >> SignUpUsernameViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.delegate = self
        
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
        
        usernameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        usernameField.enablesReturnKeyAutomatically = true
        
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
    var username:String?
    
    
    func textFieldChanged(_ target:UITextField) {
        switch target {
        case usernameField:
            break
        default:
            break
        }
        
        validateForm()
    }
    
    func validateForm() {
        username = nil
        
        self.activityIndicator.stopAnimating()
        buttonState = .none
        
        if let username = usernameField.text, username != "" {
            self.username = username
            if username.characters.count > 4 {
                activityIndicator.startAnimating()
                UserService.checkUsernameAvailability(byUsername: self.username!, completion: { username, available in
                    self.activityIndicator.stopAnimating()
                    if self.username != username { return }
                    if available {
                        self.buttonState = .valid
                    } else {
                        self.buttonState = .invalid
                    }
                })
            }
        }
    }
    
    var buttonState:SignUpButtonState = .unset
    {
        didSet {
            switch buttonState {
            case .none:
                usernameBorder.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
                usernameLabel.textColor = UIColor(white: 0.67, alpha: 1.0)
                setLoginButton(enabled: false)
                check.setImage(nil, for: .normal)
                break
            case .invalid:
                usernameBorder.backgroundColor = errorColor
                usernameLabel.textColor = errorColor
                setLoginButton(enabled: false)
                check.setImage(UIImage(named:"delete"), for: .normal)
                check.tintColor = errorColor
                check.imageEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
                break
            case .valid:
                usernameBorder.backgroundColor = accentColor
                usernameLabel.textColor = accentColor
                setLoginButton(enabled: true)
                check.setImage(UIImage(named:"check"), for: .normal)
                check.tintColor = accentColor
                check.imageEdgeInsets = UIEdgeInsets.zero
                break
            default:
                break
            }
        }
    }
    @IBAction func checkTapped(_ sender: Any) {
        if buttonState == .invalid {
            usernameField.text = ""
            validateForm()
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
        guard let username = self.username else { return }
        
        closeButton.isEnabled = false
        setLoginButton(enabled: false)
        newUser?.username = username
        self.performSegue(withIdentifier: "toPassword", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPassword" {
            let dest = segue.destination as! SignUpPasswordViewController
            dest.newUser = newUser
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        validateForm()
        usernameField.becomeFirstResponder()
        
        closeButton.isEnabled = true
        newUser?.printDescription()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usernameField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            usernameField.resignFirstResponder()
            handleSubmit()
            break
        default:
            break
        }
        
        return true
    }
    
    let ACCEPTABLE_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_."
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = CharacterSet(charactersIn: ACCEPTABLE_CHARACTERS).inverted
        let filtered: String = (string.components(separatedBy: cs) as NSArray).componentsJoined(by: "")
        
        if let _ = string.characters.index(of: "."){
            
            if let text = textField.text, text.contains(".") {
                return false
            } else if textField.text == nil || textField.text == "" {
                return false
            }
        }
        
        if let _ = string.characters.index(of: "_"){
            if let text = textField.text, text.contains("_") {
                return false
            }
        }
        
        return (string == filtered)
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
