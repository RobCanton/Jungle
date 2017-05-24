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
        delegate?.showAuthor(comment!.getAuthor())
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    fileprivate var check:Int = 0
    
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
        
        UserService.getUser(comment.getAuthor(), withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
                self.authorLabel.text = user!.username
                self.commentLabel.text = comment.getText()
                self.commentLabel.sizeToFit()
                self.userImage.loadImageAsync(user!.imageURL, completion: nil)
                self.timeLabel.text = comment.getDate().timeStringSinceNow()
            }
            
        })
        
    }
    
}
