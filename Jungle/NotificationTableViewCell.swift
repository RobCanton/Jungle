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
    
    var post:StoryItem?
    
    func setup(withNotification notification: Notification) {
        
        if notification.getType() == .comment {
            UserService.getUser(notification.getSender(), completion: { user in
                if user != nil {
                    
                    self.userImageView.clipsToBounds = true
                    self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
                    self.userImageView.contentMode = .scaleAspectFill
                    
                    self.userImageView.loadImageAsync(user!.getImageUrl(), completion: { fromCache in })
                    
                    if let postKey = notification.getPostKey() {
                        UploadService.getUpload(key: postKey, completion: { item in
                            if item != nil {
                                self.post = item
                                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                                    self.postImageView.image = image
                                })
                                self.setCommentLabel(username: user!.getUsername(), item: item!, date: notification.getDate())
                            }
                        })
                    }
                }
            })
        }
    }
    
    func setCommentLabel(username:String, item:StoryItem, date: Date) {
        let timeStr = " \(date.timeStringSinceNow())"
        var partialString = "\(username) commented on your photo."
        if item.contentType == .video {
            partialString = "\(username) commented on your video."
        }
        let str = "\(partialString)\(timeStr)"
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
        title.addAttributes(a2, range: NSRange(location: partialString.characters.count, length: timeStr.characters.count))
        
        messageLabel.attributedText = title
    }
}
