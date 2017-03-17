//
//  LoginViewController.swift
//  Riot
//
//  Created by Robert Canton on 2017-03-14.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase


class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var createAccountButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.borderWidth = 2.0
        loginButton.layer.borderColor = UIColor.black.cgColor
        
        createAccountButton.layer.borderWidth = 2.0
        createAccountButton.layer.borderColor = UIColor.black.cgColor

//        FIRAuth.auth()?.signInAnonymously() { (user, error) in
//            if error == nil {
//                self.performSegue(withIdentifier: "login", sender: self)
//            } else {
//                print(error!.localizedDescription)
//            }
//            
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = FIRAuth.auth()?.currentUser {
            self.performSegue(withIdentifier: "login", sender: self)
        }
    }
    
    @IBAction func handleCreateAccount(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toCreateAccount", sender: self)
    }
}



class CreateAccountViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var createButton: UIBarButtonItem!
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    @IBAction func handleBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    let imagePicker = UIImagePickerController()
    
    var imageTap:UITapGestureRecognizer!
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    
    @IBAction func handleCreate(_ sender: Any) {
        
        guard let email = emailField.text else { return }
        guard let username = usernameField.text else { return }
        guard let password = passwordField.text else { return }
        guard let image = profileImage else { return }
        
        backButton.isEnabled = false
        createButton.isEnabled = false
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            if error == nil && user != nil {
                print("USER: \(user.debugDescription)")
                
                UserService.uploadProfileImage(image: image, completion: { url in
                
                    if url != nil {
                        let userRef = FIRDatabase.database().reference().child("users/profile/\(user!.uid)")
                        userRef.setValue([
                            "username": username,
                            "imageURL": url
                            ], withCompletionBlock: { error, ref in
                                self.dismiss(animated: true, completion: nil)
                        })
                        
                    } else {
                        //oops
                    }
                })
                
                
                
            } else {
                print("ERROR: \(error?.localizedDescription)")
            }
        }
        
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth,height: newHeight))
        image.draw(in: CGRect(x: 0,y: 0,width: newWidth,height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func cropImageToSquare(image: UIImage) -> UIImage? {
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }
        
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }

}
