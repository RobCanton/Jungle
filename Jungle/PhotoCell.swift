//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit



class PhotoCell: UICollectionViewCell, StoryProtocol {

    @IBOutlet weak var colorView: UIView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var location:Location!
    var gradient:CAGradientLayer?
    
    var check:Int = 0
    
    var story:Story?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 0.0
        self.clipsToBounds = true
        
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
            self.timeLabel.text = story.date.timeStringSinceNow()
            break
        }
    }

    func setupLocationCell (_ story:LocationStory) {
        
        self.story = story
        self.story!.delegate = self
        self.story!.determineState()
        
        check += 1
        self.imageView.image = nil
        self.nameLabel.text = ""
        self.timeLabel.text = ""
        
        //colorView.isHidden = story.hasViewed()
        
        LocationService.sharedInstance.getLocationInfo(story.getLocationKey(), completion: { location in
            if location != nil {
                self.location = location
                self.nameLabel.text = location!.getName()
            }
        })
        
        self.timeLabel.text = story.date.timeStringSinceNow()
 
        self.colorView.backgroundColor = UIColor.clear
        self.imageView.image = nil
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
 
            
            self.nameLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
            self.timeLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
        
        })
    }
    
    func setupUserCell (_ post:StoryItem) {
        
        check += 1
        self.imageView.image = nil
        self.nameLabel.isHidden = true
        self.timeLabel.isHidden = true

        getImage(withCheck: check, post: post, completion: { check, image, fromFile in
            
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
            
        })
    }
    
    func getUploadImage(withCheck check: Int, key: String, completion: @escaping ((_ check:Int, _ item:StoryItem, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                
                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                    self.colorView.alpha = photoCellColorAlpha
                    completion(check, item!, image, fromFile)
                })
            }
        })
    }
    
    func getImage(withCheck check: Int, post:StoryItem, completion: @escaping ((_ check:Int, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.retrieveImage(byKey: post.getKey(), withUrl: post.getDownloadUrl(), completion: { image, fromFile in
            completion(check, image, fromFile)
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
