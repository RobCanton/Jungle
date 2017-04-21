//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit



class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var location:Location!
    var gradient:CAGradientLayer?
    
    var check:Int = 0
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 2.0
        self.clipsToBounds = true
    }

    func setupLocationCell (_ locationStory:LocationStory) {
        
        check += 1
        self.imageView.image = nil
        self.colorView.alpha = 0.0
        
        LocationService.sharedInstance.getLocationInfo(locationStory.getLocationKey(), completion: { location in
            if location != nil {
                self.location = location
                self.nameLabel.text = location!.getName()
            }
        })
        
        let lastPost = locationStory.getPostKeys().first!
        let key = lastPost.0
        let time = lastPost.1
        
        let date = Date(timeIntervalSince1970: time/1000)
        self.timeLabel.text = date.timeStringSinceNow()
 
        self.colorView.backgroundColor = UIColor.clear
        self.imageView.image = nil
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
    
    func setupFollowingCell (_ story:UserStory) {
        
        check += 1
        self.imageView.image = nil
        self.colorView.alpha = 0.0
        
        UserService.getUser(story.getUserId(), completion: { user in
            if user != nil {
                self.nameLabel.text = user!.getUsername()
            }
        })
        
        let lastPost = story.getPostKeys().first!
        let key = lastPost.0
        let time = lastPost.1
        
        let date = Date(timeIntervalSince1970: time/1000)
        self.timeLabel.text = date.timeStringSinceNow()
        
        self.colorView.backgroundColor = UIColor.clear
        self.imageView.image = nil
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
    
    func getUploadImage(withCheck check: Int, key: String, completion: @escaping ((_ check:Int, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                    completion(check, image, fromFile)
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
