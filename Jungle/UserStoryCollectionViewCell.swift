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
    
    func setup() {
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.clipsToBounds = true
        
        imageContainer.layer.cornerRadius = imageContainer.frame.width / 2
        imageContainer.layer.borderColor = accentColor.cgColor
        imageContainer.layer.borderWidth = 2.0
        imageContainer.clipsToBounds = true
        
//        UserService.getUser(mainStore.state.userState.uid, completion: { user in
//            self.imageView.loadImageAsync(user!.getImageUrl(), completion: { result in })
//        })
    }
    
    func setupStoryInfo(story: UserStory) {
        
        self.story = story
        story.delegate = self
        stateChange(story.state)
        
        check += 1
        
        /*UserService.getUser(story.getUserId(), completion: { user in
            if user != nil {
                self.imageView.loadImageAsync(user!.getImageUrl(), completion: { result in })
                if story.getUserId() == mainStore.state.userState.uid {
                    self.usernameLabel.text = "Me"
                    self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightBold)
                } else {
                    self.usernameLabel.text = user!.getUsername()
                    self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
                }

            }
        })*/
        
        UserService.getUser(story.getUserId(), withCheck: check, completion: { user, check1 in
        
            if user != nil && check1 == self.check {
                loadImageCheckingCache(withUrl: user!.getImageUrl(), check: self.check, completion: { image, fromCache, check2 in
                    if image != nil && check2 == self.check {
                        self.imageView.image = image
                    }
                })
                
                if story.getUserId() == mainStore.state.userState.uid {
                    self.usernameLabel.text = "Me"
                    self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightBold)
                } else {
                    self.usernameLabel.text = user!.getUsername()
                    self.usernameLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightRegular)
                }
            }
        })
    }
    
    
    
    func activateCell(_ animated:Bool) {
        if let s = story as? UserStory {
           print("REACTIVATE OLD CELL: \(s.getUserId())")
        }

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
