//
//  UserStoryCollectionViewCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class UserStoryCollectionViewCell: UICollectionViewCell, StoryProtocol {

    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var story: Story?
    
    var check = 0
    
    func setupStoryInfo(story: UserStory) {
        
        self.story = story
        story.delegate = self
        stateChange(story.state)
        
        check += 1
        
        self.imageView.layer.cornerRadius = self.imageView.frame.width / 2
        self.imageView.clipsToBounds = true
        
        self.imageContainer.layer.cornerRadius = self.imageContainer.frame.width / 2
        self.imageContainer.layer.borderColor = accentColor.cgColor
        self.imageContainer.layer.borderWidth = 2.0
        self.imageContainer.clipsToBounds = true
        
        getUserAndImage(withCheck: check, uid: story.uid, completion: { check, user, image, fromCache in
            if self.check != check { return }
            if image != nil {
                self.imageView.image = image
            }
            
            if story.uid == mainStore.state.userState.uid {
                self.usernameLabel.text = "Me"
                self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightBold)
            } else {
                self.usernameLabel.text = user.username
                self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
            }
            
        })
        
        
    }
    
    func getUserAndImage(withCheck check:Int, uid:String, completion: @escaping((_ check:Int, _ user:User, _ image: UIImage?, _ fromCache: Bool)->())) {
        
        UserService.getUser(uid, completion: { user in
            
            if user != nil  {
                loadImageUsingCacheWithURL(user!.imageURL, completion: { image, fromCache in
                    completion(check, user!, image, fromCache)
                })
            }
        })
    }
    
    
    
    func activateCell(_ animated:Bool) {

        imageContainer.layer.cornerRadius = imageContainer.frame.width / 2
        imageContainer.clipsToBounds = true
        if animated {
            let color:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
            color.fromValue = UIColor.clear.cgColor
            color.toValue = accentColor.cgColor
            imageContainer.layer.borderColor = accentColor.cgColor
            
            
            let both:CAAnimationGroup = CAAnimationGroup()
            both.duration = 0.30
            both.animations = [color]
            both.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            imageContainer.layer.add(both, forKey: "color and Width")
        } else {
            imageContainer.layer.borderColor = accentColor.cgColor
        }
    }
    
    func stateChange(_ state:UserStoryState) {
        
        switch state {
        case .notLoaded:
            story?.downloadItems()
            break
        case .loadingItemInfo:
            break
        case .itemInfoLoaded:
            itemsLoaded()
            break
        case .loadingContent:
            loadingContent()
            break
        case .contentLoaded:
            contentLoaded()
            break
        }
    }
    
    
    func itemsLoaded() {
        guard let items = story?.items else { return }

    }
    
    func loadingContent() {
    }
    
    func contentLoaded() {
        
    }
    
    

}
