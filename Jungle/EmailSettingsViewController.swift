//
//  EmailSettingsViewController.swift
//  
//
//  Created by Robert Canton on 2017-06-10.
//
//

import UIKit
import Firebase

class EmailSettingsViewController: UIViewController {

    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addNavigationBarBackdrop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.becomeFirstResponder()
        emailTextField.text = UserService.email
        
        if UserService.isEmailVerified {
            self.resendButton.isEnabled = false
            resendButton.isHidden = true
            messageLabel.text = "Email verified! 😬"
            emailTextField.textColor = UIColor.black
        } else {
            self.resendButton.setTitle("Resend Verification Email", for: .normal)
            self.resendButton.isEnabled = true
            resendButton.isHidden = false
            messageLabel.text = "We've sent a verification email to you. Please open the link to finish verifying your address."
            emailTextField.textColor = errorColor
        }
        
        
        let refresh = UIBarButtonItem(image: UIImage(named: "refresh"), style: .plain, target: self, action: #selector(handleRefresh))
        self.parent?.navigationItem.rightBarButtonItem = refresh
        
    }
    
    func handleRefresh() {
        Auth.auth().currentUser?.reload { _ in }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        emailTextField.resignFirstResponder()
    }

    @IBAction func resendVerificationEmail(_ sender: Any) {
        self.resendButton.isEnabled = false
        self.resendButton.setTitle("Email Sent", for: .normal)
        UserService.sendVerificationEmail { success in
            if success {
                let alert = UIAlertController(title: "Email Sent", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            } else {
                return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Unable to send email.")
            }
        }
    }


}
