//
//  ConversationViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-13.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ConversationViewCell: UITableViewCell, GetUserProtocol {
    

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
    @IBOutlet weak var sentArrow: UIImageView!
    @IBOutlet weak var unreadDot: UIView!
    
    var user:User?
    
    
    var conversation:Conversation? {
        didSet{
            userImageView.image = nil
            messageLabel.text = ""
            usernameLabel.text = ""
            timeLabel.text = ""
            userImageView.cropToCircle()
            unreadDot.cropToCircle()
            UserService.getUser(conversation!.getPartnerId(), completion: { _user in
                if let user = _user {
                    self.userLoaded(user: user)
                }
            })
        }
    }
    
    @IBOutlet weak var messageLabelLeading: NSLayoutConstraint!
    
    func userLoaded(user: User) {
        self.user = user
        userImageView.contentMode = .scaleAspectFill
            
        userImageView.loadImageAsync(user.imageURL, completion: nil)
        usernameLabel.text = user.username
        
        let isSender = conversation!.sender == mainStore.state.userState.uid
        if conversation!.isMediaMessage {
            if isSender {
                messageLabel.text = "You sent a post"
            } else {
               messageLabel.text = "Sent a post"
            }
            messageLabel.textColor = UIColor.lightGray
        } else {
            let lastMessage = conversation!.getLastMessage()
            messageLabel.text = lastMessage
            messageLabel.textColor = UIColor.black
        }
        if isSender {
            messageLabelLeading.constant = 6.0
            sentArrow.heightAnchor.constraint(equalToConstant: 14.0).isActive = true
            sentArrow.isHidden = false
        } else {
            messageLabelLeading.constant = 0.0
            sentArrow.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
            sentArrow.isHidden = true
        }
        self.layoutSubviews()
        
        timeLabel.text = conversation!.getDate().timeStringSinceNow()
        
        if !conversation!.getSeen() {
            usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
            unreadDot.isHidden = false
        } else {
            
            usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
            unreadDot.isHidden = true
        }
    }
    
    
    override func awakeFromNib() {
       
    }
    
}
