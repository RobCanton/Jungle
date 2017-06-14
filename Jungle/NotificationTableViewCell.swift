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
        let type = notification.type
        if type != .comment && type != .comment_also && type != .comment_to_sub &&  type != .like && type != .mention { return }
        self.notification = notification
        
        userTap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        
        guard let postKey = notification.postKey else { return }
        
        getUser(withCheck: check, uid: notification.sender, completion: { check, user in
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
                UploadService.retrieveImage(byKey: item!.key, withUrl: item!.downloadUrl, completion: { image, fromFile in
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
        
        self.userImageView.loadImageAsync(user.imageURL, completion: { fromCache in })
        
        UploadService.retrieveImage(byKey: post.key, withUrl: post.downloadUrl, completion: { image, fromFile in
            self.postImageView.image = image
        })
        
        let type = notification.type
        if type == .comment {
            var prefix = ""
            if let numCommenters = notification.count {
                if numCommenters == 2 {
                    prefix = "and 1 other "
                } else if numCommenters > 2 {
                    prefix = "and \(getNumericShorthandString(numCommenters - 1)) others "
                }
            }
            var suffix = "."
            if let text = notification.text {
                suffix = ": \"\(text)\""
            }
            setMessageLabel(username: user.username, message: " \(prefix)commented on your post\(suffix)", date: notification.date)
        } else if type == .comment_also {
            var prefix = ""
            if let numCommenters = notification.count {
                if numCommenters == 2 {
                    prefix = "and 1 other "
                } else if numCommenters > 2 {
                    prefix = "and \(getNumericShorthandString(numCommenters - 1)) others "
                }
            }
            var suffix = "."
            if let text = notification.text {
                suffix = ": \"\(text)\""
            }
            setMessageLabel(username: user.username, message: " \(prefix)also commented\(suffix)", date: notification.date)
        } else if type == .comment_to_sub {
            var prefix = ""
            if let numCommenters = notification.count {
                if numCommenters == 2 {
                    prefix = "and 1 other "
                } else if numCommenters > 2 {
                    prefix = "and \(getNumericShorthandString(numCommenters - 1)) others "
                }
            }
            var suffix = "."
            if let text = notification.text {
                suffix = ": \"\(text)\""
            }
            setMessageLabel(username: user.username, message: " \(prefix)commented on a post you are following\(suffix)", date: notification.date)
        } else if type == .like {
            var prefix = ""
            if let numLikes = notification.count {
                if numLikes == 2 {
                    prefix = "and 1 other "
                } else if numLikes > 2 {
                    prefix = "and \(getNumericShorthandString(numLikes - 1)) others "
                }
            }
            
            setMessageLabel(username: user.username, message: " \(prefix)liked your post.", date: notification.date)
        } else if type == .mention {
            setMessageLabel(username: user.username, message: " mentioned you in a comment.", date: notification.date)
        }
    }
    
    func setMessageLabel(username:String, message:String, date: Date) {
        let timeStr = " \(date.timeStringSinceNow())"
        let str = "\(username)\(message)\(timeStr)"
        let msg = message.utf16
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
        title.addAttributes(a2, range: NSRange(location: username.characters.count + msg.count, length: timeStr.characters.count))
        
        messageLabel.attributedText = title
        
    }
    
    func userTapped() {
        guard let notification = self.notification else { return }
        userTappedHandler?(notification.sender)
    }
}
