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
    var uid:String?
    
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
        
        UserService.getUser(story.getUserId(), completion: { user in
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
        })
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
