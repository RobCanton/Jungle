//
//  CommentCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import ActiveLabel

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var commentLabel: ActiveLabel!
    
    var authorTapped:((_ userId:String)->())?
    
    var comment:Comment!
    @IBOutlet weak var userImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView = nil
        backgroundColor = UIColor.clear
        
        selectedBackgroundView = nil

        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        userImage.addGestureRecognizer(tap)
        userImage.isUserInteractionEnabled = true
        
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        authorLabel.addGestureRecognizer(usernameTap)
        authorLabel.isUserInteractionEnabled = true
        
        //authorLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        //commentLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        
        commentLabel.enabledTypes = [.mention]
        commentLabel.customColor[ActiveType.mention] = accentColor
        commentLabel.handleMentionTap { mention in
            print("MENTIONED: \(mention)")
            
            let controller = UserProfileViewController()
            controller.username = mention
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
        }
    
       
    }
    
    var tap:UITapGestureRecognizer!

    func handleTap(sender:UITapGestureRecognizer) {
        authorTapped?(comment.getAuthor())
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    fileprivate var check:Int = 0
    var user:User?
    
    func setContent(comment:Comment) {
        
        check += 1
        
        self.comment = comment
        userImage.cropToCircle()
        
        backgroundColor = UIColor.clear
        backgroundView = nil
        
        UserService.getUser(comment.getAuthor(), withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
                self.user = user!
                self.authorLabel.text = user!.getUsername()
                self.commentLabel.text = comment.getText()
                self.commentLabel.sizeToFit()
                self.userImage.loadImageAsync(user!.getImageUrl(), completion: nil)
                self.timeLabel.text = comment.getDate().timeStringSinceNow()
            }
            
        })
        
    }
    
    
    
    
    @IBOutlet weak var timeLabel: UILabel!
    func toggleTimeStamp() {
        
    }
    
}
