//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import QuartzCore

protocol StoryHeaderProtocol {
    func showUser(_ uid:String)
    func showViewers()
    func showLikes()
}

class PostAuthorView: UIView {

    
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var authorUsernameLabel: UILabel!
    @IBOutlet weak var timeLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var viewsView: UIView!
    @IBOutlet weak var viewsLabel: UILabel!
    
    @IBOutlet weak var likesView: UIView!
    @IBOutlet weak var likesLabel: UILabel!
    
    var delegate:StoryHeaderProtocol?
    
    var uid:String?
    var authorTap:UITapGestureRecognizer!
    var likesTap:UITapGestureRecognizer!
    var viewsTap:UITapGestureRecognizer!

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()

        authorImageView.layer.cornerRadius = authorImageView.frame.width/2
        authorImageView.clipsToBounds = true
 
        viewsView.layer.cornerRadius = 3.0
        viewsView.clipsToBounds = true
        
        likesView.layer.cornerRadius = 3.0
        likesView.clipsToBounds = true
        
        authorTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        likesTap = UITapGestureRecognizer(target: self, action: #selector(likesTapped))
        viewsTap = UITapGestureRecognizer(target: self, action: #selector(viewsTapped))
        
        authorUsernameLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)

    }
    
    func setAuthorInfo(user:User, post:StoryItem) {
       
        self.authorUsernameLabel.text = user.getDisplayName()
        self.uid = user.getUserId()
        self.timeLabel.text = post.getDateCreated()!.timeStringSinceNow()
        
        
        self.viewsView.removeGestureRecognizer(self.viewsTap)
        self.viewsView.addGestureRecognizer(self.viewsTap)
        
        
        self.likesView.removeGestureRecognizer(self.likesTap)
        self.likesView.addGestureRecognizer(self.likesTap)
        
        setViews(post: post)
        setLikes(post: post)
    }
    
    func setAuthorImage(image:UIImage) {
        self.authorImageView.image = image
        self.authorImageView.removeGestureRecognizer(self.authorTap)
        self.authorImageView.addGestureRecognizer(self.authorTap)
        
        
        let superView = self.authorImageView.superview!
        superView.isUserInteractionEnabled = true
        superView.removeGestureRecognizer(self.authorTap)
        superView.addGestureRecognizer(self.authorTap)
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if uid != nil {
            delegate?.showUser(uid!)
        }
    }
    
    func likesTapped(gesture:UITapGestureRecognizer) {
        delegate?.showLikes()
    }
    
    func viewsTapped(gesture:UITapGestureRecognizer) {
        delegate?.showViewers()
    }
    
    func setViews(post:StoryItem) {
        let views = post.viewers.count
        self.viewsLabel.text = "\(views)"
        if views > 0 {
            viewsView.isHidden = false
        } else {
            viewsView.isHidden = true
        }
    }
    
    func setLikes(post:StoryItem) {
        let likes = post.likes.count
        self.likesLabel.text = "\(likes)"
        if likes > 0 {
            likesView.isHidden = false
        } else {
            likesView.isHidden = true
        }
    }

    func cleanUp() {
        uid = nil
        authorImageView.image = nil
        authorUsernameLabel.text = nil
    }
    
    
}
