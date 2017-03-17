//
//  UserStoryTableViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import Firebase

class UserStoryTableViewCell: UITableViewCell, StoryProtocol {


    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    @IBOutlet weak var userBadge: UIImageView!
    
    var userStory:Story?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageContainer.layer.cornerRadius = imageContainer.frame.width/2
        imageContainer.clipsToBounds = true
        imageContainer.layer.borderColor = UIColor.clear.cgColor
        imageContainer.layer.borderWidth = 1.25
        
        contentImageView.layer.cornerRadius = contentImageView.frame.width/2
        contentImageView.clipsToBounds = true
        
        timeLabel.textColor = UIColor.gray
    }
    
    func activate(_ animated:Bool) {
        guard let story = userStory else { return }
        guard let items = story.items else { return }
        
        var borderColor = accentColor.cgColor
//        if story.hasViewedAll() {
//            borderColor = UIColor.clear.cgColor
//        }
        if items.count == 0 { return }
        if animated {
            let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
            color.fromValue = UIColor.black.cgColor
            color.toValue = borderColor
            imageContainer.layer.borderColor = borderColor
            
            
            let both:CAAnimationGroup = CAAnimationGroup()
            both.duration = 0.30
            both.animations = [color]
            both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            imageContainer.layer.add(both, forKey: "color and Width")
        } else {
            imageContainer.layer.borderColor = borderColor
        }
    }
    
    func deactivate() {
        imageContainer.layer.borderColor = UIColor.clear.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var imageAlpha:CGFloat = 1.0
    
    func setUserStory(_ story:Story, uid:String) {
        self.userStory = story
        story.delegate = self
        stateChange(story.state)
        guard let user = FIRAuth.auth()?.currentUser else { return }

        UserService.getUser(uid, completion: { user in
            if user != nil {
                
                
                
                let current_uid = user!.getUserId()
                
                if user!.getUserId() == current_uid {
                    
                    self.usernameLabel.text = "Your Story"
                } else {
                    self.usernameLabel.text = user!.getUsername()
                }
                
                
                // Load in image to avoid blip in story view
                loadImageUsingCacheWithURL(user!.getImageUrl(), completion: { image, fromCache in
                    //self.contentImageView.image = image
                })
                
                UploadService.getUpload(key: story.getPosts().first!, completion: { item in
                    if item != nil {
                        

                        self.imageAlpha = 1.0
                        
                        self.contentImageView.alpha = self.imageAlpha
                        
                        UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                            self.contentImageView.image = image
                            if !fromFile {
                                self.contentImageView.alpha = 0.0
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.contentImageView.alpha = self.imageAlpha
                                })
                            } else {
                                self.contentImageView.alpha = self.imageAlpha
                            }
                        })
                    }
                })
                self.setSubtitle()
            }
        })
    }
    

    func setToEmptyMyStory() {
        
        self.usernameLabel.text = "Your Story"
        self.timeLabel.text = "+ Tap to add"
        imageContainer.layer.borderColor = UIColor.clear.cgColor
        guard let user = FIRAuth.auth()?.currentUser else { return }

//        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
//            self.contentImageView.image = image
//        })
        

    }
    
    var activityIndicator:UIActivityIndicatorView?
    
    func setToLoadingCell() {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator!.activityIndicatorViewStyle = .gray
        activityIndicator!.startAnimating()
        activityIndicator!.center = self.center
        self.addSubview(activityIndicator!)
    }
    
    func clearLoading() {
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
    }
    
    
    func stateChange(_ state:UserStoryState) {

        switch state {
        case .notLoaded:
            userStory?.downloadItems()
            self.usernameLabel.textColor = UIColor.gray
            break
        case .loadingItemInfo:
            self.usernameLabel.textColor = UIColor.gray
            break
        case .itemInfoLoaded:
            self.usernameLabel.textColor = UIColor.gray
            itemsLoaded()
            break
        case .loadingContent:
            self.usernameLabel.textColor = UIColor.gray
            loadingContent()
            break
        case .contentLoaded:
            self.usernameLabel.textColor = UIColor.black
            contentLoaded()
            break
        }
    }
    
    var numComments = 0
    var numLikes = 0
    var numViews = 0
    func itemsLoaded() {
        guard let items = userStory?.items else { return }
        if items.count > 0 {
            
            
            numComments = 0
            numLikes = 0
            numViews = 0
            for item in items {
                numComments += item.comments.count
                numLikes += item.likes.count
                numViews += item.viewers.count
            }
            
            
            activate(false)
            /*loadImageUsingCacheWithURL(lastItem.getDownloadUrl().absoluteString, completion: { image, fromCache in
                
                if !fromCache {
                    self.contentImageView.alpha = 0.0
                    UIView.animateWithDuration(0.30, animations: {
                        self.contentImageView.alpha = 1.0
                    })
                } else {
                    self.contentImageView.alpha = 1.0
                }
                self.contentImageView.image = image
            })*/
        }
    }
    
    func loadingContent() {
        timeLabel.text = "Loading..."
    }
    
    func contentLoaded() {
        setSubtitle()
        
    }
    
    func setSubtitle() {
        guard let story = userStory else { return }
        
        let lastPost = story.getPostKeys().first!
        let time = lastPost.1
        
        let date = Date(timeIntervalSince1970: time/1000)
        self.timeLabel.text = date.timeStringSinceNowWithAgo()
    }
}
