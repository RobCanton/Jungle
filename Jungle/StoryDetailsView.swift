//
//  StoryDetailsView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-16.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class StoryDetailsView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!

    @IBOutlet weak var commentsLabel: UILabel!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        

    }
    
    func setInfo(item:StoryItem, user:User) {
        let username = user.getUsername()
        let str = "\(username) \(item.caption)"
        
        imageView.loadImageAsync(user.getImageUrl(), completion: nil)
        
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: username) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold),
            ]
            title.addAttributes(a, range: NSRange(location: index, length: username.characters.count))
        }
        
        
        captionLabel.attributedText = title
        setCommentsLabel(numComments: item.comments.count)
        
    }
    
    func setCommentsLabel(numComments:Int) {
        if numComments > 0 {
            if numComments == 1 {
                commentsLabel.text = "1 comment"
            } else {
                commentsLabel.text = "\(numComments) comments"
            }
           
        } else {
            commentsLabel.text = "Write a comment"
        }
    }

}
