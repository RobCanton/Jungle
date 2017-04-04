//
//  NotificationFollowCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-01.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class NotificationFollowCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var followButton: UIButton!
    
    var unfollowHandler:((_ user:User)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        followButton.layer.borderWidth = 1.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var status:FollowingStatus = .None
    var user:User?
    
    func setup(withNotification notification: Notification) {
        if notification.getType() != .follow { return }
        
        followButton.layer.cornerRadius = 4.0
        followButton.clipsToBounds = true
        followButton.backgroundColor = accentColor
        
        UserService.getUser(notification.getSender(), completion: { user in
            if user != nil {
                self.user = user
                self.userImageView.clipsToBounds = true
                self.userImageView.layer.cornerRadius = self.userImageView.frame.width/2
                self.userImageView.contentMode = .scaleAspectFill
                
                self.userImageView.loadImageAsync(user!.getImageUrl(), completion: { fromCache in })
                
                self.setLabel(username: user!.getUsername(), date: notification.getDate())
                
            }
        })
        
        setUserStatus(status: checkFollowingStatus(uid: notification.getSender()))
    }
    
    func setLabel(username:String, date: Date) {
        let timeStr = " \(date.timeStringSinceNow())"
        var partialString = "\(username) started following you."

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
    
    func setUserStatus(status:FollowingStatus) {
        
        self.status = status
        switch status {
        case .CurrentUser:
            followButton.backgroundColor = UIColor.white
            followButton.isHidden = true
            followButton.layer.borderColor = UIColor.clear.cgColor
            break
        case .None:
            followButton.backgroundColor = accentColor
            followButton.setTitle("Follow", for: .normal)
            followButton.setTitleColor(UIColor.white, for: .normal)
            followButton.tintColor = UIColor.white
            followButton.isHidden = false
            followButton.layer.borderColor = UIColor.clear.cgColor
            break
        case .Requested:
            followButton.backgroundColor = UIColor.white
            followButton.setTitle("Requested", for: .normal)
            followButton.setTitleColor(UIColor.black, for: .normal)
            followButton.tintColor = UIColor.black
            followButton.isHidden = false
            followButton.layer.borderColor = UIColor.clear.cgColor
            break
        case .Following:
            followButton.backgroundColor = UIColor.white
            followButton.setTitle("Following", for: .normal)
            followButton.setTitleColor(UIColor.black, for: .normal)
            followButton.isHidden = false
            followButton.layer.borderColor = UIColor.black.cgColor
            break
        }
    }
    
    @IBAction func handleFollowButton(_ sender: Any) {
        guard let user = self.user else { return }
        
        switch status {
        case .CurrentUser:
            break
        case .Following:
            unfollowHandler?(user)
            break
        case .None:
            setUserStatus(status: .Requested)
            UserService.followUser(uid: user.getUserId())
            break
        case .Requested:
            break
        }
    }
}
