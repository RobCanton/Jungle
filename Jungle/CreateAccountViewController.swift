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
        
        emailField.layer.cornerRadius = 8.0
        emailField.clipsToBounds = true
        emailField.delegate = self
        
        usernameField.layer.cornerRadius = 8.0
        usernameField.clipsToBounds = true
        usernameField.delegate = self
        
        passwordField.layer.cornerRadius = 8.0
        passwordField.clipsToBounds = true
        passwordField.delegate = self
        
        signupButton.layer.cornerRadius = 8.0
        signupButton.clipsToBounds = true
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        imageTap = UITapGestureRecognizer(target: self, action: #selector(showImagePicker))
        profileImageView.addGestureRecognizer(imageTap)
        profileImageView.isUserInteractionEnabled = true
        
        imagePicker.delegate = self
        imagePicker.navigationBar.isTranslucent = false
        
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
        guard let email = emailField.text else { return }
        guard let username = usernameField.text else { return }
        guard let password = passwordField.text else { return }
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
                                self.dismiss(animated: true, completion: nil)
                        })
                        
                    } else {
                        //oops
                    }
                })
            } else {
                print("ERROR: \(error)")
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
