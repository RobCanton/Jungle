//
//  PasswordRecoveryViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-18.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class PasswordRecoveryViewController:UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var blurbLabel: UILabel!
    
    @IBOutlet weak var emailTextField: InsetTextField!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func handleDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleSubmit(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        
        FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { error in
            if error == nil {
                Alerts.showStatusSuccessAlert(inWrapper: nil, withMessage: "Email sent!")
                self.dismiss(animated: true, completion: nil)
                return
            } else {
                Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to send recovery email.")
                return
            }
        })
    }
    
    var gradientView:UIView!
    var gradient:CAGradientLayer?
    
    let fieldColor = UIColor(white: 1.0, alpha: 0.32)
    let invalidFieldColor = UIColor(red: 1.0, green: 128/255, blue: 136/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientView = UIView(frame: view.bounds)
        self.view.insertSubview(gradientView, at: 0)
        gradientView.backgroundColor = UIColor.white
        
        self.gradient?.removeFromSuperlayer()
        self.gradient = CAGradientLayer()
        self.gradient!.frame = self.gradientView.bounds
        self.gradient!.colors = [
            lightAccentColor.cgColor,
            darkAccentColor.cgColor
        ]
        self.gradient!.locations = [0.0, 1.0]
        self.gradient!.startPoint = CGPoint(x: 0, y: 0)
        self.gradient!.endPoint = CGPoint(x: 0, y: 1)
        self.gradientView.layer.insertSublayer(self.gradient!, at: 0)
        
        emailTextField.layer.borderColor = UIColor.clear.cgColor
        emailTextField.layer.borderWidth = 2.0
        emailTextField.layer.cornerRadius = 8.0
        emailTextField.clipsToBounds = true
        emailTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(validateForm), for: .editingChanged)
        
        
        submitButton.layer.cornerRadius = 8.0
        submitButton.clipsToBounds = true
        
    }
    
    func validateForm(_ target: UITextField) {
        if let text = target.text, text != "" {
            if isValidEmail(testStr: text) {
                emailTextField.layer.borderColor = UIColor.white.cgColor
            } else {
                emailTextField.layer.borderColor = invalidFieldColor.cgColor
            }
        } else {
            emailTextField.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
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


class PasswordRecoverySentViewController:UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var blurbLabel: UILabel!
    

    @IBOutlet weak var submitButton: UIButton!

    
    @IBAction func handleSubmit(_ sender: Any) {
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
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
            lightAccentColor.cgColor,
            darkAccentColor.cgColor
        ]
        self.gradient!.locations = [0.0, 1.0]
        self.gradient!.startPoint = CGPoint(x: 0, y: 0)
        self.gradient!.endPoint = CGPoint(x: 0, y: 1)
        self.gradientView.layer.insertSublayer(self.gradient!, at: 0)
        
        
        submitButton.layer.cornerRadius = 8.0
        submitButton.clipsToBounds = true
        
    }
    
    
    override var prefersStatusBarHidden: Bool {
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
