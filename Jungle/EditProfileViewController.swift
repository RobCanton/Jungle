//
//  EditProfileViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Popover

protocol EditProfileProtocol {
    func getFullUser()
}

class Badge {
    private(set) var key:String
    private(set) var icon:String
    private(set) var title:String
    private(set) var desc:String
    
    var isAvailable = false
    
    init(key:String, icon:String, title:String, desc:String)
    {
        self.key   = key
        self.icon  = icon
        self.title = title
        self.desc = desc
    }
}


func < (lhs: Badge, rhs: Badge) -> Bool {
    return lhs.title < rhs.title
}

func > (lhs: Badge, rhs: Badge) -> Bool {
    return lhs.title > rhs.title
}

func == (lhs: Badge, rhs: Badge) -> Bool {
    return lhs.title == rhs.title
}


class EditProfileViewController: UITableViewController, UIPickerViewDelegate{

    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var bioPlaceholder: UITextField!
    @IBOutlet weak var badgeCell: UITableViewCell!


    
    var imageTap: UITapGestureRecognizer!
    var headerView:UIView!
    var selectedBadgeIndex:IndexPath?
    var didEdit = false
    
    var profileImageURL:String?
    
    let imagePicker = UIImagePickerController()
    
    var profileImage:UIImage?
    var profileImageView:UIImageView!
    
    var delegate:EditProfileProtocol?
    
    var badgeCollectionView:UICollectionView!
    var _badges = [Badge]()
    
    var itemSideLength:CGFloat!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSideLength = (UIScreen.main.bounds.width - 4.0) / 4.0
        
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
            profileImageView.loadImageAsync(user.imageURL, completion: { _ in
                self.imageTap = UITapGestureRecognizer(target: self, action: #selector(self.showProfilePhotoMessagesView))
                self.headerView.isUserInteractionEnabled = true
                self.headerView.addGestureRecognizer(self.imageTap)
            })
            bioTextView.text = user.bio
        }
        
        bioTextView.delegate = self
        bioPlaceholder.isHidden = !bioTextView.text.isEmpty

        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        
        var available = [Badge]()
        var unavailable = [Badge]()
        
        for (key, badge) in badges {
            if badge.isAvailable {
                available.append(badge)
            } else {
                unavailable.append(badge)
            }
        }
        
        available.sort(by: { $0 > $1 })
        unavailable.sort(by: { $0 > $1 })
        
        

        self._badges = available
        self._badges.append(contentsOf: unavailable)
        
        for i in 0..<_badges.count {
            let badge = _badges[i]
            if badge.key == mainStore.state.userState.user!.badge {
                selectedBadgeIndex = IndexPath(item: i, section: 0)
            }
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        
        badgeCollectionView = UICollectionView(frame: badgeCell.contentView.bounds, collectionViewLayout: layout)
        badgeCollectionView.backgroundColor = UIColor.white
        
        let nib = UINib(nibName: "BadgeCell", bundle: nil)
        badgeCollectionView.register(nib, forCellWithReuseIdentifier: "badgeCell")
        badgeCollectionView.delegate = self
        badgeCollectionView.dataSource = self
        badgeCell.contentView.addSubview(badgeCollectionView)
        
        
        badgeCollectionView.reloadData()
        
        
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
        
        if let index = selectedBadgeIndex {
            let badge = _badges[index.item]
            
            basicProfileObj["badge"] = badge.key
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
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength)
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

extension EditProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        for badge in self._badges {
            print(badge.icon)
        }
        return self._badges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "badgeCell", for: indexPath as IndexPath) as! BadgeCell
        cell.setup(withBadge: self._badges[indexPath.item])
        if let selected = selectedBadgeIndex {
            if selected.item == indexPath.item {
                cell.isSelected = true
            }
        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! BadgeCell
        if let index = selectedBadgeIndex {
            collectionView.deselectItem(at: index, animated: false)
            let oldCell = collectionView.cellForItem(at: index) as! BadgeCell
            oldCell.isSelected = false
            
            if index.item == indexPath.item {
                selectedBadgeIndex = nil
            } else {
                
                selectedBadgeIndex = indexPath
            }
            
        } else {
            selectedBadgeIndex = indexPath
        }
        
        if let index = selectedBadgeIndex {
            
            let badge = _badges[index.item]
            if badge.isAvailable {
                showDetailPopover(badge, cell)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! BadgeCell
        print("Deselected: \(cell.isSelected)")
    }
    
    func showDetailPopover(_ badge: Badge, _ cell:UIView) {
        let width = self.view.frame.width * 0.60
        let descWidth = width - 16.0
        
        let text = badge.desc
        let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightRegular)
        
        let label = UILabel(frame: CGRect(x: 0, y: 2, width: width, height: 36))
        label.text = badge.title
        label.font = UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightSemibold)
        label.textAlignment = .center
        
        let size = UILabel.size(withText: text, forWidth: descWidth, withFont: font)
        
        let label2 = UILabel(frame: CGRect(x: 8, y: label.frame.height, width: descWidth, height: size.height))
        label2.text = text
        label2.font = font
        label2.textAlignment = .center
        label2.numberOfLines = 0
        
        
        let aView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: label.frame.height + size.height + 14.0))
        aView.backgroundColor = UIColor.lightGray
        
        aView.addSubview(label)
        aView.addSubview(label2)
        
        let options = [
            .type(.down),
            .cornerRadius(8),
            .animationIn(0.2),
            .blackOverlayColor(UIColor(white: 0.0, alpha: 0.07)),
            .arrowSize(CGSize(width: 16.0, height: 10.0))
            ] as [PopoverOption]
        
        
        let popover = Popover(options: options, showHandler: nil, dismissHandler: nil)
        popover.show(aView, fromView: cell)
    }
    
}
