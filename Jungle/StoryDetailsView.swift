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
    
    @IBOutlet weak var likeButton: UIButton!
    
    var currentUserMode = false
    var liked = false
    
    fileprivate var actionButtonHandler:((_ like:Bool?)->())?
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
    
    
    func setInfo(item:StoryItem, user:User, actionHandler:((_ like:Bool?)->())?) {
        actionButtonHandler = actionHandler
        
        if item.getAuthorId() == mainStore.state.userState.uid {
            currentUserMode = true
            likeButton.setImage(UIImage(named: "trash"), for: .normal)
        } else {
            currentUserMode = false
            likeButton.setImage(UIImage(named: "like"), for: .normal)
        }
        
        likeButton.isHidden = false
        
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
        setCommentsLabel(numLikes: item.likes.count,numComments: item.comments.count)
        
    }
    
    func setCommentsLabel(numLikes:Int, numComments:Int) {
        var likesStr = ""
        if numLikes > 0 {
            likesStr = "♥ \(numLikes) · "
        }
        
        if numComments > 0 {
            if numComments == 1 {
                commentsLabel.text = "\(likesStr)1 comment"
            } else {
                commentsLabel.text = "\(likesStr)\(numComments) comments"
            }
           
        } else {
            commentsLabel.text = "Write a comment"
        }
    }
    
    @IBAction func likeTapped(_ sender: UIButton) {
        if currentUserMode {
            actionButtonHandler?(nil)
        } else {
            setLikedStatus(!self.liked, animated: true)
            actionButtonHandler?(liked)
        }
    }
    
    func setLikedStatus(_ _liked:Bool, animated: Bool) {
        if currentUserMode { return }
        self.liked = _liked
        
        if self.liked  {
            likeButton.setImage(UIImage(named: "liked"), for: .normal)
            if animated {
                likeButton.setImage(UIImage(named: "liked"), for: .normal)
                self.likeButton.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                
                UIView.animate(withDuration: 0.5, delay: 0.0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 1.6,
                               options: .curveEaseOut,
                               animations: {
                                self.likeButton.transform = CGAffineTransform.identity
                },
                               completion: nil)
            }
            
        } else {
            likeButton.setImage(UIImage(named:"like"), for: .normal)
        }
    }

}
