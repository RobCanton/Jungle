//
//  FollowingPhotoCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-24.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class FollowingPhotoCell: UICollectionViewCell, StoryProtocol {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var colorView: UIView!
    
    var check:Int = 0
    var gradient:CAGradientLayer?
    var story:Story?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.imageView.superview!.layer.cornerRadius = 4.0
        self.imageView.superview!.clipsToBounds = true
    }
    
    func stateChange(_ state:UserStoryState) {
        guard let story = self.story else { return }
        
        
        switch state {
        case .notLoaded:
            story.downloadItems()
            break
        case .loadingItemInfo:
            break
        case .itemInfoLoaded:
            break
        case .loadingContent:
            timeLabel.text = "Loading..."
            break
        case .contentLoaded:
            guard let lastPost = story.getPostKeys().first else { return }
            let time = lastPost.1
            let date = Date(timeIntervalSince1970: time/1000)
            self.timeLabel.text = date.timeStringSinceNow()
            break
        }
    }

    
    func setupFollowingCell (_ story:UserStory) {
        
        self.story = story
        self.story!.delegate = self
        self.story!.determineState()
        
        check += 1
        self.imageView.image = nil
        self.colorView.alpha = 0.0

        UserService.getUser(story.getUserId(), completion: { user in
            if user != nil {
                if user!.getUserId() == mainStore.state.userState.uid {
                    self.nameLabel.text = "Me"
                    self.nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightBold)
                } else {
                   self.nameLabel.text = user!.getUsername()
                    self.nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightMedium)
                }
            }
        })
        
        let lastPost = story.getPostKeys().first!
        let key = lastPost.0
        let time = lastPost.1
        
        let date = Date(timeIntervalSince1970: time/1000)
        self.timeLabel.text = date.timeStringSinceNow()
        self.imageView.image = nil
        self.colorView.backgroundColor = UIColor.clear
        
        getUploadImage(withCheck: check, key: key, completion: { check, image, fromFile in
            
            if self.check != check { return }
            self.imageView.image = image
            if !fromFile {
                self.imageView.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.imageView.alpha = 1.0
                })
            } else {
                self.imageView.alpha = 1.0
            }
            
            if image != nil {
                let avgColor = image!.areaAverage()
                let saturatedColor = avgColor.modified(withAdditionalHue: 0, additionalSaturation: 0.3, additionalBrightness: 0.20)
                self.gradient?.removeFromSuperlayer()
                self.gradient = CAGradientLayer()
                self.gradient!.frame = self.colorView.bounds
                self.gradient!.colors = [UIColor.clear.cgColor, saturatedColor.cgColor]
                self.gradient!.locations = [0.0, 1.0]
                self.gradient!.startPoint = CGPoint(x: 0, y: 0)
                self.gradient!.endPoint = CGPoint(x: 0, y: 1)
                self.colorView.layer.insertSublayer(self.gradient!, at: 0)
                self.colorView.alpha = photoCellColorAlpha
            }
            
            self.nameLabel.applyShadow(radius: 2.0, opacity: 0.5, height: 1.0, shouldRasterize: true)
            self.timeLabel.applyShadow(radius: 2.0, opacity: 0.5, height: 1.0, shouldRasterize: true)
            
        })
    }
    
    func getUploadImage(withCheck check: Int, key: String, completion: @escaping ((_ check:Int, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                    completion(check, image, fromFile)
                })
            }
        })
    }
    
    func fadeInInfo(animated:Bool) {
        if animated {
            self.colorView.alpha = 0.0
            self.nameLabel.alpha = 0.0
            self.timeLabel.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.colorView.alpha = photoCellColorAlpha
                self.nameLabel.alpha = 1.0
                self.timeLabel.alpha = 1.0
            })
        } else{
            self.colorView.alpha = photoCellColorAlpha
            self.nameLabel.alpha = 1.0
            self.timeLabel.alpha = 1.0
        }
        
    }
    
    func fadeOutInfo() {
        self.colorView.alpha = 0.0
        self.nameLabel.alpha = 0.0
        self.timeLabel.alpha = 0.0
    }
}
