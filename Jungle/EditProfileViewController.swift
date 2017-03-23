//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol EditProfileProtocol {
    func getFullUser()
}

class EditProfileViewController: UITableViewController {

    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var bioPlaceholder: UITextField!
    
    var imageTap: UITapGestureRecognizer!
    var headerView:UIView!
    
    var didEdit = false
    
    var profileImageURL:String?
    
    let imagePicker = UIImagePickerController()
    
    var profileImage:UIImage?
    var profileImageView:UIImageView!
    
    var delegate:EditProfileProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 104))
        headerView.contentMode = .scaleAspectFill
        headerView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        profileImageView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        profileImageView.center = CGPoint(x: headerView.frame.width/2, y: headerView.frame.height/2)
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        headerView.addSubview(profileImageView)
    

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 106 // Something reasonable to help ios render your cells
        
        tableView.tableHeaderView = headerView
        

        if let user = mainStore.state.userState.user {
            profileImageView.loadImageAsync(user.getImageUrl(), completion: { _ in
                self.imageTap = UITapGestureRecognizer(target: self, action: #selector(self.showProfilePhotoMessagesView))
                self.headerView.isUserInteractionEnabled = true
                self.headerView.addGestureRecognizer(self.imageTap)
            })
            bioTextView.text = user.getBio()
        }
        
        bioTextView.delegate = self
        bioPlaceholder.isHidden = !bioTextView.text.isEmpty

        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    @IBAction func handleCancel(sender: AnyObject) {
        
        if didEdit {
            let cancelAlert = UIAlertController(title: "Unsaved Changes", message: "You have unsaved changes. Are you sure you want to cancel?", preferredStyle: UIAlertControllerStyle.alert)
            
            cancelAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            cancelAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            present(cancelAlert, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func handleSave(sender: AnyObject) {
        
        cancelButton.isEnabled = false
        cancelButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.gray], for: .normal)
        headerView.isUserInteractionEnabled = false
        bioTextView.isUserInteractionEnabled = false
        title = "Saving..."
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        if self.profileImage != nil {
            
            UserService.uploadProfileImage(image: self.profileImage!, completion: { url in
                self.updateUser(profileURL: url)
            })
            
        } else {
            updateUser(profileURL: nil)
        }
    }
    
    func updateUser(profileURL:String?) {
        var basicProfileObj = [String:Any]()

        basicProfileObj["bio"] = bioTextView.text as Any?
        
        if let imageURL = profileURL {
            print("PROFILE URL: \(imageURL)")
            basicProfileObj["imageURL"] = imageURL as Any?
        }
        
        let uid = mainStore.state.userState.uid
        let basicProfileRef = UserService.ref.child("users/profile/\(uid)")
        
        
        basicProfileRef.updateChildValues(basicProfileObj, withCompletionBlock: { error, ref in
            if error == nil {
               self.retrieveUpdatedUser()
            } else {
                print(error!.localizedDescription)
            }
        })
    }
    
    func retrieveUpdatedUser() {
        let uid = mainStore.state.userState.uid
        
        dataCache.removeObject(forKey: "user-\(uid)" as NSString)
        UserService.getUser(uid, completion: { _user in
            if let user = _user {
                mainStore.dispatch(UserIsAuthenticated(user: user))
                self.dismiss(animated: true, completion: {
                    self.delegate?.getFullUser()
                })
            }
        })
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.profileImage = nil
            if let image = cropImageToSquare(image: pickedImage) {
                self.profileImage = resizeImage(image: image, newWidth: 150)
                self.profileImageView.image = self.profileImage
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func previewNewImage(image:UIImage) {
        
        
    }
    
    func uploadProfileImages(largeImage:UIImage, smallImage:UIImage) {
        
    }
    
    
    
    func showProfilePhotoMessagesView() {
        bioTextView.resignFirstResponder()
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
}

extension EditProfileViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        didEdit = true
        switch textView {
        case bioTextView:
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
            bioPlaceholder.isHidden = !textView.text.isEmpty
            break
        default:
            break
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= 240
    }
}
