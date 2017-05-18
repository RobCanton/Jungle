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
    
    
    @IBOutlet weak var unreadDot: UIView!
    
    var user:User?
    
    
    var conversation:Conversation? {
        didSet{
            unreadDot.cropToCircle()
            UserService.getUser(conversation!.getPartnerId(), completion: { _user in
                if let user = _user {
                    self.userLoaded(user: user)
                }
            })
            
            let lastMessage = conversation!.getLastMessage()
            messageLabel.text = lastMessage
            timeLabel.text = conversation!.getDate().timeStringSinceNow()
            
            
            if !conversation!.getSeen() {
                usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
                unreadDot.isHidden = false
            } else {

                usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
                unreadDot.isHidden = true
            }
            
        }
    }
    
    
    func userLoaded(user: User) {
        self.user = user
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = userImageView.frame.width/2
        userImageView.contentMode = .scaleAspectFill
            
        userImageView.loadImageAsync(user.getImageUrl(), completion: nil)
        usernameLabel.text = user.getUsername()
    }
    
    
    override func awakeFromNib() {
       
    }
    
}
