//
//  CreateAccountViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//
import UIKit
import Foundation
import Firebase

let usernameLengthLimit = 16

class CreateAccountViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate {
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var signupButton: UIButton!
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func handleBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    let imagePicker = UIImagePickerController()
    
    var imageTap:UITapGestureRecognizer!
    
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
        
        emailField.layer.borderColor = UIColor.clear.cgColor
        emailField.layer.borderWidth = 2.0
        emailField.layer.cornerRadius = 8.0
        emailField.clipsToBounds = true
        emailField.delegate = self
        emailField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged)
        
        usernameField.layer.borderColor = UIColor.clear.cgColor
        usernameField.layer.borderWidth = 2.0
        usernameField.layer.cornerRadius = 8.0
        usernameField.clipsToBounds = true
        usernameField.delegate = self
        usernameField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged)
        
        passwordField.layer.borderColor = UIColor.clear.cgColor
        passwordField.layer.borderWidth = 2.0
        passwordField.layer.cornerRadius = 8.0
        passwordField.clipsToBounds = true
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(textViewChanged), for: .editingChanged)
        
        signupButton.layer.cornerRadius = 8.0
        signupButton.clipsToBounds = true
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        imageTap = UITapGestureRecognizer(target: self, action: #selector(showImagePicker))
        profileImageView.addGestureRecognizer(imageTap)
        profileImageView.isUserInteractionEnabled = true
        
        imagePicker.delegate = self
        imagePicker.navigationBar.isTranslucent = false
        
        signupEnabled(false)
        
    }
    
    var croppedImage:UIImage!
    var profileImage:UIImage?
    
    func showImagePicker() {
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.profileImage = nil
            
            if let image = cropImageToSquare(image: pickedImage) {
                self.profileImage = resizeImage(image: image, newWidth: 150)
                self.profileImageView.image = self.profileImage
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func handleSignupButton(_ sender: Any) {
        guard let email = emailField.text, email != "" else { return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Please enter a valid email address.")}
        guard let username = usernameField.text, username != "" else { return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Please enter a username") }
        guard let password = passwordField.text, password != "" else { return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Please enter a password.") }
        guard let image = profileImage else { return }
        
        backButton.isEnabled = false
        signupButton.isEnabled = false
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            if error == nil && user != nil {
                print("USER: \(user.debugDescription)")
                
                UserService.uploadProfileImage(image: image, completion: { url in
                    
                    if url != nil {
                        let userRef = FIRDatabase.database().reference().child("users/profile/\(user!.uid)")
                        userRef.setValue([
                            "username": username,
                            "imageURL": url,
                            "bio":""
                            ], withCompletionBlock: { error, ref in
                                
                                FIRDatabase.database().reference().child("lookup/username/uid/\(username)").setValue(user!.uid)
                                self.dismiss(animated: true, completion: nil)
                        })
                        
                    } else {
                        self.reset()
                        return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Error creating account.")
                    }
                })
            } else {
                self.reset()
                return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Error creating account.")
            }
        }
    }
    
    func reset() {
        backButton.isEnabled = true
        signupButton.isEnabled = true
    }
    
    func signupEnabled(_ enabled:Bool) {
        if enabled {
            signupButton.isEnabled = true
            signupButton.alpha = 1.0
        } else {
            signupButton.isEnabled = false
            signupButton.alpha = 0.6
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewChanged(_ target: UITextField){
        switch target {
        case usernameField:
            target.text = target.text?.lowercased()
            validateUsername()
            break
        default:
            break
        }
        validateForm()
    }
    
    func checkUsernameAvailability(_ _username:String?) {
        guard let username = _username else { return usernameAvailable = false }
        let usernameRef = UserService.ref.child("lookup/username/uid/\(username)")
        usernameRef.observeSingleEvent(of: .value, with: { snapshot in
            self.usernameAvailable = !snapshot.exists()
            self.validateForm()
        })
    }
    
    var usernameAvailable = false
    
    func validateEmail() -> Bool {
        if let text = emailField.text, text != "" {
            if isValidEmail(testStr: text) {
                emailField.layer.borderColor = UIColor.white.cgColor
                return true
            } else {
                emailField.layer.borderColor = invalidFieldColor.cgColor
            }
        } else {
            emailField.layer.borderColor = UIColor.clear.cgColor
        }
        return false
    }
    
    func validateUsername() {
        
        if let text = usernameField.text, text != "" {
            if text.characters.count >= 5 {
                checkUsernameAvailability(text)
            } else {
                usernameAvailable = false
            }
        } else {
            usernameAvailable = false
        }
    }
    
    func validatePassword() -> Bool {
        if let text = passwordField.text, text != "" {
            if text.characters.count >= 6 {
                passwordField.layer.borderColor = UIColor.white.cgColor
                return true
            } else {
                passwordField.layer.borderColor = invalidFieldColor.cgColor
            }
        } else {
            passwordField.layer.borderColor = UIColor.clear.cgColor
        }
        return false
    }
    
    func validateForm() {
        let validEmail = validateEmail()
        let validPassword = validatePassword()
        if usernameAvailable {
            usernameField.layer.borderColor = UIColor.white.cgColor
        } else if usernameField.text == nil || usernameField.text == "" {
            usernameField.layer.borderColor = UIColor.clear.cgColor
        } else {
            usernameField.layer.borderColor = invalidFieldColor.cgColor
        }
        
        if validEmail && usernameAvailable && validPassword {
            signupEnabled(true)
        } else {
            signupEnabled(false)
        }

    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === usernameField {
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            //return newLength <= usernameLengthLimit
            if newLength > usernameLengthLimit { return false }
            
            // Create an `NSCharacterSet` set
            let inverseSet = NSCharacterSet(charactersIn:".0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted
            let components = string.components(separatedBy: inverseSet)
            
            // Rejoin these components
            let filtered = components.joined(separator: "")  // use join("", components) if you are using Swift 1.2
            return string == filtered
        }
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
}

func isValidEmail(testStr:String) -> Bool {
    // print("validate calendar: \(testStr)")
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: testStr)
}
