//
//  NotificationTableViewCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var messageLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var notification:Notification?
    var user:User?
    var post:StoryItem?
    var check = 0;
    
    var userTappedHandler:((_ uid:String)->())?
    var userTap:UITapGestureRecognizer!
    
    func setup(withNotification notification: Notification) {
        
        if notification.getType() != .comment && notification.getType() != .like { return }
        self.notification = notification
        
        userTap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        
        guard let postKey = notification.getPostKey() else { return }
        
        getUser(withCheck: check, uid: notification.getSender(), completion: { check, user in
            if self.check != check { return }
            self.user = user
            self.checkContentLoaded()
        })
        
        getPost(withCheck: check, key: postKey, completion: { check, item in
            if self.check != check { return }
            self.post = item
            self.checkContentLoaded()
        })
    }
    
    func getUser(withCheck check:Int, uid:String, completion: @escaping((_ check:Int, _ user:User?)->())) {
        UserService.getUser(uid, completion: { user in
            completion(check, user)
        })
    }
    
    func getPost(withCheck check:Int, key:String, completion: @escaping((_ check:Int, _ item:StoryItem?)->())) {
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                    self.postImageView.image = image
                })
            }
            completion(check, item)
        })
    }
    
    func checkContentLoaded() {
        guard let notification = self.notification else { return }
        guard let user = self.user else { return }
        guard let post = self.post else { return }

        self.userImageView.clipsToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
        self.userImageView.contentMode = .scaleAspectFill
        
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(userTap)
        
        self.userImageView.loadImageAsync(user.getImageUrl(), completion: { fromCache in })
        
        UploadService.retrieveImage(byKey: post.getKey(), withUrl: post.getDownloadUrl(), completion: { image, fromFile in
            self.postImageView.image = image
        })
        
        if notification.getType() == .comment {
            setMessageLabel(username: user.getUsername(), message: " commented on your post.", date: notification.getDate())
        } else if notification.getType() == .like {
            setMessageLabel(username: user.getUsername(), message: " liked your post.", date: notification.getDate())
        }
    }
    
    func setMessageLabel(username:String, message:String, date: Date) {
        let timeStr = " \(date.timeStringSinceNow())"
        let str = "\(username)\(message)\(timeStr)"
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        let a: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold),
            ]
        title.addAttributes(a, range: NSRange(location: 0, length: username.characters.count))
        
        
        let a2: [String: AnyObject] = [
            NSForegroundColorAttributeName : UIColor(white: 0.67, alpha: 1.0)
            ]
        title.addAttributes(a2, range: NSRange(location: username.characters.count + message.characters.count, length: timeStr.characters.count))
        
        messageLabel.attributedText = title
    }
    
    func userTapped() {
        guard let notification = self.notification else { return }
        userTappedHandler?(notification.getSender())
    }
}
