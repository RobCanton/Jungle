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
    @IBOutlet weak var commentsLabel: UILabel!
    
    @IBOutlet weak var commentsIcon: UIImageView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var dotBorder: UIView!
    @IBOutlet weak var newDot: UIView!
    var check:Int = 0
    var gradient:CAGradientLayer?
    var story:Story?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.imageView.superview!.layer.cornerRadius = 4.5
        self.imageView.superview!.clipsToBounds = true
        
        dotBorder.cropToCircle()
        newDot.cropToCircle()

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
//        case .loadingContent:
//            timeLabel.text = "Loading..."
//            
//            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
//                self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
//            }, completion: { _ in
//            
//            })
//            break
//        case .contentLoaded:
//            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
//                self.transform = CGAffineTransform.identity
//            }, completion: { _ in
//                
//            })
//            
//            self.timeLabel.text = story.date.timeStringSinceNow()
//            break
        }
    }

    
    func setupFollowingCell (_ story:UserStory, showDot: Bool) {
        

        self.story = story
        self.story!.delegate = self
        self.story!.determineState()
        
        check += 1
        self.imageView.image = nil
        self.nameLabel.text = ""
        self.timeLabel.text = ""
        self.colorView.alpha = 0.0
        
        if story.uid == mainStore.state.userState.uid {
            //colorView.isHidden = true
            newDot.isHidden = true
            dotBorder.isHidden = true
        } else {
            let viewed = story.hasViewed()
            //colorView.isHidden = viewed
            newDot.isHidden = showDot ? viewed : true
            dotBorder.isHidden = showDot ? viewed : true
        }
        
        getUser(withCheck: check, uid: story.uid, completion: { check, user in
            if self.check != check { return }
            if user != nil {
                if user!.uid == mainStore.state.userState.uid {
                    self.nameLabel.text = "Me"
                    self.nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightBold)
                } else {
                    self.nameLabel.text = user!.username
                    self.nameLabel.font = UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightMedium)
                }
            }
        })
        

        self.timeLabel.text = story.date.timeStringSinceNow()
        self.imageView.image = nil
        self.colorView.backgroundColor = UIColor.clear
        
        getUploadImage(withCheck: check, key: story.lastPostKey, completion: { check, item, image, fromFile in
            
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
            
            self.gradient?.removeFromSuperlayer()
            if let color = item.getColor() {
                self.gradient = CAGradientLayer()
                self.gradient!.frame = self.colorView.bounds
                self.gradient!.colors = [UIColor.clear.cgColor, color.withAlphaComponent(0.75).cgColor]
                self.gradient!.locations = [0.0, 1.0]
                self.gradient!.startPoint = CGPoint(x: 0, y: 0)
                self.gradient!.endPoint = CGPoint(x: 0, y: 1)
                self.gradient!.shouldRasterize = false
                self.colorView.layer.shouldRasterize = false
                self.gradient!.drawsAsynchronously = true
                self.colorView.layer.drawsAsynchronously = true
                self.colorView.layer.insertSublayer(self.gradient!, at: 0)
                self.colorView.alpha = photoCellColorAlpha
            }
            
            self.nameLabel.applyShadow(radius: 2.5, opacity: 0.90, height: 1.0, shouldRasterize: true)
            self.timeLabel.applyShadow(radius: 2.5, opacity: 0.90, height: 1.0, shouldRasterize: true)
            //self.commentsLabel.applyShadow(radius: 2.5, opacity: 0.90, height: 1.0, shouldRasterize: true)
            //self.commentsIcon.applyShadow(radius: 2.5, opacity: 0.50, height: 1.0, shouldRasterize: true)
            
        })
    }
    
    func getUser(withCheck check: Int, uid:String, completion: @escaping ((_ check:Int, _ user:User?)->())) {
        UserService.getUser(uid, completion: { user in
            completion(check, user)
        })
    }
    
    func getUploadImage(withCheck check: Int, key: String, completion: @escaping ((_ check:Int, _ item:StoryItem, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                
                UploadService.retrieveImage(byKey: item!.key, withUrl: item!.downloadUrl, completion: { image, fromFile in
                    completion(check, item!, image, fromFile)
                })
            }
        })
    }
    
    func fadeInInfo(animated:Bool) {
        if animated {
            self.dotBorder.alpha = 0.0
            self.newDot.alpha = 0.0
            self.colorView.alpha = 0.0
            self.nameLabel.alpha = 0.0
            self.timeLabel.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.dotBorder.alpha = 1.0
                self.newDot.alpha = 1.0
                self.colorView.alpha = photoCellColorAlpha
                self.nameLabel.alpha = 1.0
                self.timeLabel.alpha = 1.0
            })
        } else{
            self.dotBorder.alpha = 1.0
            self.newDot.alpha = 1.0
            self.colorView.alpha = photoCellColorAlpha
            self.nameLabel.alpha = 1.0
            self.timeLabel.alpha = 1.0
        }
        
    }
    
    func fadeOutInfo() {
        self.dotBorder.alpha = 0.0
        self.newDot.alpha = 0.0
        self.colorView.alpha = 0.0
        self.nameLabel.alpha = 0.0
        self.timeLabel.alpha = 0.0
    }
}
