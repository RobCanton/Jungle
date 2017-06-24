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
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var tap:UITapGestureRecognizer!
    
    weak var comment:Comment?
    weak var delegate:CommentCellProtocol?
    
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
        
        commentLabel.enabledTypes = [.mention]
        commentLabel.customColor[ActiveType.mention] = accentColor
        commentLabel.handleMentionTap { mention in
            
            let controller = UserProfileViewController()
            controller.username = mention
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
        }
    
       
    }

    func handleTap(sender:UITapGestureRecognizer) {
        if comment == nil { return }
        delegate?.showAuthor(comment!.author)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    fileprivate var check:Int = 0
    
    var shadow = true
    
    func setContent(comment:Comment) {
        
        self.authorLabel.text = ""
        self.commentLabel.text = ""
        self.commentLabel.sizeToFit()
        self.userImage.image = nil
        self.timeLabel.text = ""
        
        check += 1
        
        self.comment = comment
        userImage.cropToCircle()
        
        backgroundColor = UIColor.clear
        backgroundView = nil
        
        UserService.getUser(comment.author, withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
                self.authorLabel.text = user!.username
                self.authorLabel.alpha = 1.0
                self.userImage.loadImageAsync(user!.imageURL, completion: nil)
                self.timeLabel.text = comment.date.timeStringSinceNow()
            } else {
                self.authorLabel.text = "Unknown"
                self.authorLabel.alpha = 0.5
            }
            
            self.commentLabel.text = comment.text
            self.commentLabel.sizeToFit()
            self.timeLabel.text = comment.date.timeStringSinceNow()
        })
        if shadow {
            authorLabel.applyShadow(radius: 0.25, opacity: 0.6, height: 0.25, shouldRasterize: true)
            commentLabel.applyShadow(radius: 0.25, opacity: 0.6, height: 0.25, shouldRasterize: true)
        } else {
            authorLabel.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: true)
            commentLabel.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: true)
        }
        
    }
    
}
