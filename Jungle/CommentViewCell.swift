//
//  CommentViewCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import UIKit

class CommentViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    var comment:Comment!
    var check:Int = 0
    
    func setContent(comment:Comment) {
        
        userImageView.cropToCircle()
        check += 1
        
        self.comment = comment
        messageLabel.cropToCircle()
        
        backgroundColor = UIColor.clear
        backgroundView = nil
        
        UserService.getUser(comment.author, withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
                self.setMessageLabel(username: user!.username, message: comment.text)
                self.userImageView.loadImageAsync(user!.imageURL, completion: nil)
            }
            
        })
        
    }
    
    func setMessageLabel(username:String, message:String) {
        let str = "\(username) \(message)"
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        let a: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold),
            ]
        title.addAttributes(a, range: NSRange(location: 0, length: username.characters.count))
        
        messageLabel.attributedText = title
    }
    
}
