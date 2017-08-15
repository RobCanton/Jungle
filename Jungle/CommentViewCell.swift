//
//  CommentCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import ActiveLabel
import Firebase


class DetailedCommentCell: UITableViewCell {
    
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var commentLabel: ActiveLabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var verifiedBadge: UIImageView!
    @IBOutlet weak var likeButton: DOFavoriteButton!
    @IBOutlet weak var likeButtonContainer: UIButton!
    @IBOutlet weak var numLikesLabel: UILabel!

    @IBOutlet weak var replyButton: UIButton!
    var numLikesRef:DatabaseReference?
    var likedRef:DatabaseReference?
    var tap:UITapGestureRecognizer!
    var isOP = false
    var check:Int = 0
    var liked = false
    
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
        delegate?.commentAuthorTapped(comment!)
    }
    
    func setContent(itemKey:String, comment:Comment) {
        
        self.authorLabel.text = nil
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

        authorLabel.textColor = UIColor.black
        commentLabel.textColor = UIColor.black
        
        if isCurrentUserId(id: comment.author) {
            replyButton.setTitle("Remove", for: .normal)
            replyButton.setTitle("Remove", for: .highlighted)
            replyButton.setTitle("Remove", for: .selected)
            replyButton.setTitle("Remove", for: .focused)
            //contentView.backgroundColor = UIColor(red: 231/255, green: 1.0, blue: 249/255, alpha: 1.0)
            contentView.backgroundColor = UIColor(red: 241/255, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            replyButton.setTitle("Reply", for: .normal)
            replyButton.setTitle("Reply", for: .highlighted)
            replyButton.setTitle("Reply", for: .selected)
            replyButton.setTitle("Reply", for: .focused)
            //contentView.backgroundColor = UIColor.clear
            contentView.backgroundColor = UIColor.white
        }
        
        setNumberOfLikes(comment.numLikes)
        
        
        
        likedRef?.removeAllObservers()
        likedRef = UserService.ref.child("uploads/commentLikes/\(itemKey)/\(comment.key)/\(userState.uid)")
        self.likeButton.deselect()
        self.liked = false
        
        likedRef?.observe(.value, with: { snapshot in
            
            guard let parent = snapshot.ref.parent else { return }
            if parent.key != comment.key { return }

            if snapshot.exists() {
                self.liked = true
                self.likeButton.select(animated: false)
            } else {
                self.liked = false
                self.likeButton.deselect()
            }
        }, withCancel: { error in
            print("Error observing comment likes")
        })
        
        numLikesRef?.removeAllObservers()
        numLikesRef = UserService.ref.child("uploads/comments/\(itemKey)/\(comment.key)/likes")
        numLikesRef?.observe(.value, with: { snapshot in
            guard let parent = snapshot.ref.parent else { return }
            
            if parent.key != comment.key { return }
            
            if let value = snapshot.value as? Int {
                comment.numLikes = value
                self.setNumberOfLikes(comment.numLikes )
            }
        }, withCancel: { error in
            print("Error observing num comment likes")
        })
        
        if let anonComment = comment as? AnonymousComment {
            setupAnonymousComment(anonComment)
            return
        }
        self.userImage.backgroundColor = UIColor(white: 1.0, alpha: 0.35)
        
        UserService.getUser(comment.author, withCheck: check, completion: { user, check in
            if user != nil && check == self.check{
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
                } else {
                    self.verifiedBadge.image = nil
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
    
    func reset() {
        self.likedRef?.removeAllObservers()
        self.liked = false
        self.likeButton.deselect()
        self.numLikesRef?.removeAllObservers()
    }
    
    func setNumberOfLikes(_ value:Int) {
        if value == 0 {
            numLikesLabel.text = nil
        } else if value == 1 {
            numLikesLabel.text = "1 like"
        } else {
            numLikesLabel.text = "\(value) likes"
        }
    }
    
    func setupAnonymousComment(_ comment:AnonymousComment) {
        UploadService.retrieveAnonImage(withCheck: self.check, withName: comment.animal) { check, image, fromFile in
            if check != self.check { return }
            self.userImage.image = image
        }
        let color = darkerColorForColor(color: comment.color)
        
        self.authorLabel.textColor = color
        self.userImage.backgroundColor = comment.color
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
    
    @IBAction func likeTapped(_ sender: Any) {
        guard let comment = self.comment else { return }
        delegate?.commentLikeTapped(comment, !liked)
        if !liked {
            self.liked = true
            self.likeButton.select(animated:true)
            comment.numLikes += 1
            self.setNumberOfLikes(comment.numLikes)
        } else {
            self.liked = false
            self.likeButton.deselect()
            comment.numLikes -= 1
            self.setNumberOfLikes(comment.numLikes)
        }
    }
    
    @IBAction func replyTapped(_ sender: Any) {
        guard let comment = self.comment else { return }
        guard let username = self.authorLabel.text else { return }
        delegate?.commentReplyTapped(comment, username)
    }
}
