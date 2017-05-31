//
//  SignUpBirthdayViewController.swift
//  Jungle
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

class SignUpBirthdayViewController: UIViewController {
    
    @IBOutlet weak var topGradientView: UIView!
    
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var dateField: UITextField!
    
    func recieveUserInfo(firstname:String, lastname:String?) {
        
    }
    
    var birthdate:Date?
    var closeButton:UIButton!
    
    weak var newUser:NewUser?
    
    deinit {
        print("Deinit >> SignUpBirthdayViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        
        setLoginButton(enabled: false)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setLoginButton(enabled: birthdate != nil)
        closeButton.isEnabled = true
    }
  
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        birthdate = sender.date
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        dateField.text = formatter.string(from: sender.date)
        
        setLoginButton(enabled: true)
        
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
        guard let birthdate = self.birthdate else { return }
        
        closeButton.isEnabled = true
        setLoginButton(enabled: false)
        let now = Date()
        let calendar = Calendar.current
        
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
        let age = ageComponents.year!
        
        if age < 12 {
            let alert = UIAlertController(title: nil, message: "Sorry, looks like you're not eligible for Jungle... but thanks for checking us out!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                self.performSegue(withIdentifier: "unwindToMenu", sender: self)
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            newUser?.birthday = birthdate.timeIntervalSince1970
            self.performSegue(withIdentifier: "toUsername", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUsername" {
            let dest = segue.destination as! SignUpUsernameViewController
            dest.newUser = newUser
        }
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
