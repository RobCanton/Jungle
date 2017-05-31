//
//  SignUpProfilePictureViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Firebase
import Foundation
import UIKit
import NVActivityIndicatorView

class SignUpProfilePictureViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    weak var newUser:NewUser?
    
    @IBOutlet weak var submitButton: UIButton!
    var imagePicker:UIImagePickerController!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    var tap:UITapGestureRecognizer!
    var closeButton:UIButton!
    var croppedImage:UIImage!
    var profileImage:UIImage?
    var activityView:NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
    
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        profileImageView.cropToCircle()
        profileImageView.isUserInteractionEnabled = true
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.isTranslucent = false
        
        tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tap)
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.clipsToBounds = true
        
        view.addSubview(closeButton)
        
        profileImage = profileImageView.image
        
        activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .ballBeat, color: UIColor.white, padding: 1.0)
        activityView.center = submitButton.center
        view.addSubview(activityView)

    }
    
    func handleDismiss() {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func handleSubmit(_ sender: Any) {
        guard let image = profileImage else { return }
        guard let newUser = newUser else { return }
        guard let email = newUser.email else { return }
        guard let password = newUser.password else { return }
        guard let firstname = newUser.firstname else { return }
        guard let username = newUser.username else { return }
        
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
        submitButton.setTitle("", for: .normal)
        closeButton.isEnabled = false
        
        activityView.startAnimating()
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error == nil && user != nil {
                print("USER: \(user.debugDescription)")
                
                UserService.uploadProfileImage(image: image, completion: { url in
                    
                    if url != nil, let uid = user?.uid {
                        let userRef = Database.database().reference().child("users/profile/\(uid)")
                        var userProfile = [
                            "firstname": firstname,
                            "username": username,
                            "imageURL": url,
                            "bio":""
                        ]
                        if let lastname = newUser.lastname {
                            userProfile["lastname"] = lastname
                        }
                        
                        userRef.setValue(userProfile, withCompletionBlock: { error, ref in
                            
                            if error != nil {
                    
                                print("Error: \(error!.localizedDescription)")
                            }
                            
                            self.performSegue(withIdentifier: "unwindToLoginScreen", sender: self)
                        })
                        
                    } else {
                        print("Error: \(error!.localizedDescription)")
                        self.reset()
                        return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Error creating account.")
                    }
                })
            } else {
                print("Error: \(error!.localizedDescription)")
                return Alerts.showStatusFailAlert(inWrapper: nil, withMessage: "Error creating account.")
            }
        }
    }
    
    func reset() {
        submitButton.isEnabled = true
        submitButton.backgroundColor = accentColor
        submitButton.setTitle("Done", for: .normal)
        closeButton.isEnabled = true
        activityView.stopAnimating()
    }
    
    func profileTapped() {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
