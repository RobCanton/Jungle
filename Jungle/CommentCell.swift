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
    @IBOutlet weak var verifiedBadge: UIImageView!
    
    var tap:UITapGestureRecognizer!
    
    weak var comment:Comment?
    weak var delegate:CommentCellProtocol?
    
    var isOP = false
    
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
        print("HMM")
        if comment == nil { return }
        print("WHAT?")
        delegate?.commentAuthorTapped(comment!)
        //delegate?.showAuthor(comment!.author)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    fileprivate var check:Int = 0
    
    var shadow = true
    @IBOutlet weak var timeLabelLeadingConstraint: NSLayoutConstraint!
    
    func setContent(comment:Comment, lightMode:Bool) {
        
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
        verifiedBadge.image = nil
        timeLabelLeadingConstraint.constant = 8.0
        
        if lightMode {
            authorLabel.textColor = UIColor.white
            commentLabel.textColor = UIColor.white
            timeLabel.textColor = UIColor.white
        } else {
            authorLabel.textColor = UIColor.black
            commentLabel.textColor = UIColor.black
            timeLabel.textColor = UIColor.gray
        }
        
        
        if shadow {
            authorLabel.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
            commentLabel.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        } else {
            authorLabel.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: true)
            commentLabel.applyShadow(radius: 0, opacity: 0, height: 0, shouldRasterize: true)
        }
        
        if let anonComment = comment as? AnonymousComment {
            setupAnonymousComment(anonComment, lightMode)
            return
        }
        self.userImage.backgroundColor = UIColor(white: 1.0, alpha: 0.35)
        
        UserService.getUser(comment.author, withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
                //self.authorLabel.setUsernameWithBadge(username: user!.username, badge: user!.badge, fontSize: 14.0, fontWeight: UIFontWeightSemibold)
                self.self.authorLabel.text = user!.username
                self.authorLabel.alpha = 1.0
                
                loadImageCheckingCache(withUrl: user!.imageURL, check: check) { image, fromFile, check in
                    if check == self.check {
                        self.userImage.image = image
                    }
                }
                self.timeLabel.text = comment.date.timeStringSinceNow()
                
                if user!.verified {
                    self.verifiedBadge.image = UIImage(named: "verified_white")
                    self.timeLabelLeadingConstraint.constant = 22.0
                } else {
                    self.verifiedBadge.image = nil
                    self.timeLabelLeadingConstraint.constant = 8.0
                }
            } else {
                self.authorLabel.text = "Unknown"
                self.authorLabel.alpha = 0.5
            }
            
            self.commentLabel.text = comment.text
            self.commentLabel.sizeToFit()
            self.timeLabel.text = comment.date.timeStringSinceNow()
        })
        
        
    }
    
    func setupAnonymousComment(_ comment:AnonymousComment, _ lightMode:Bool) {
        UploadService.retrieveAnonImage(withCheck: self.check, withName: comment.animal) { check, image, fromFile in
            if check != self.check { return }
            self.userImage.image = image
        }
        let color = lightMode ? comment.color : darkerColorForColor(color: comment.color)
        
        self.authorLabel.textColor = color
        self.userImage.backgroundColor = comment.color
        //self.imageBackground.backgroundColor = comment.color
        if let anonID = userState.anonID, anonID == comment.author {
            self.authorLabel.setAnonymousName(anonName: comment.anonName, color: color, suffix: "[YOU]", fontSize: 14.0)
        } else if isOP {
            self.authorLabel.setAnonymousName(anonName: comment.anonName, color: color, suffix: "[OP]", fontSize: 14.0)
        } else {
            self.authorLabel.text = comment.anonName
        }
        
        self.authorLabel.alpha = 1.0
        self.commentLabel.text = comment.text
        self.commentLabel.sizeToFit()
        self.timeLabel.text = comment.date.timeStringSinceNow()
        
    }
    
}
