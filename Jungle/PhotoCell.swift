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

    @IBOutlet weak var firstIcon: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    
    @IBOutlet weak var secondIcon: UIImageView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var crown: UIImageView!
    @IBOutlet weak var crownLabel: UILabel!
    
    @IBOutlet weak var overlay: UIView!
    var location:Location!
    var gradient:CAGradientLayer?
    
    var check:Int = 0
    var privateLock:UIImageView?
    var privateLabel:UILabel?
    
    weak var story:Story?
    weak var post:StoryItem?

    @IBOutlet weak var guardView: UIView!
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
            self.timeLabel.text = story.date.timeStringSinceNow()
            story.downloadItems()
            break
        case .loadingItemInfo:
            timeLabel.text = "Loading..."
            break
        case .itemInfoLoaded:
            self.timeLabel.text = story.date.timeStringSinceNow()
            break
        case .loadingContent:
            timeLabel.text = "Loading..."
            break
        case .contentLoaded:
            self.timeLabel.text = story.date.timeStringSinceNow()
            break
        }
    }
    
    func setCrownStatus(isKing:Bool) {
        crown.isHidden = !isKing
        crownLabel.isHidden = true//!isKing
    }
    
    var viewMoreView:UIView?
    var viewMoreLabel:UILabel?
    
    
    func viewMore(_ isMoreCell:Bool) {
        viewMoreView?.removeFromSuperview()
        viewMoreLabel?.removeFromSuperview()
        viewMoreView = nil
        viewMoreLabel = nil
        
        self.overlay.isHidden = isMoreCell
        if isMoreCell {
            let margin:CGFloat = 8.0
            
            viewMoreView = UIView(frame: CGRect(x: margin, y: margin + self.bounds.height * 0.6 , width: self.bounds.width - margin * 2.0, height: self.bounds.height * 0.4 - margin * 2.0))
            viewMoreView!.backgroundColor = UIColor.clear
            
            
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            blur.frame = viewMoreView!.bounds
            viewMoreView!.addSubview(blur)
            
            viewMoreView!.layer.cornerRadius = 4.0
            viewMoreView!.clipsToBounds = true
            
            viewMoreLabel = UILabel(frame: viewMoreView!.bounds)
            viewMoreLabel!.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightSemibold)
            viewMoreLabel!.textAlignment = .center
            viewMoreLabel!.textColor = UIColor.white
            viewMoreLabel!.numberOfLines = 0
            viewMoreLabel!.text = "View More"
            
            self.addSubview(viewMoreView!)
            viewMoreView!.addSubview(viewMoreLabel!)
        }
        
    }
    
    func setupCell (withUserStory story: UserStory) {
        self.story = story
        self.story!.delegate = self
        self.story!.determineState()
        
        check += 1
        self.imageView.image = nil
        self.nameLabel.text = ""
        self.timeLabel.text = ""
        self.firstIcon.isHidden = true
        self.firstLabel.isHidden = true
        self.secondIcon.isHidden = true
        self.secondLabel.isHidden = true
        self.timeLabel.isHidden = false
        self.timeLabel.text = story.date.timeStringSinceNow()
        
        self.colorView.backgroundColor = UIColor.clear
        self.imageView.image = nil
        
        
        getUser(withCheck: check, uid: story.uid, completion: { check, user in
            if self.check != check { return }
            if user != nil {
                if user!.uid == mainStore.state.userState.uid {
                    self.nameLabel.text = "Me"
                    self.nameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightBold)
                } else {
                    self.nameLabel.text = user!.fullname
                    self.nameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)
                }
            }
        })
        
        
        
        getUploadImage(withCheck: check, key: story.lastPostKey, completion: { check, item, image, fromFile in
            
            
            if self.check != check { return }
            self.guardView.isHidden = !item.shouldBlock
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
            
            //self.nameLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
            //self.timeLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
            
        })
    }
    
    func setPrivate(_ on:Bool) {
        privateLock?.removeFromSuperview()
        privateLabel?.removeFromSuperview()
        if on {
            privateLock = UIImageView(frame: CGRect(x: 4, y: 4, width:12, height: 12))
            privateLock?.tintColor = UIColor.white
            privateLock?.image = UIImage(named: "lock_white")
            
            privateLabel = UILabel(frame: CGRect(x: 20, y: 4, width: self.frame.width - 22, height: 16))
            privateLabel?.font = UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightRegular)
            privateLabel?.textColor = UIColor.white
            privateLabel?.text = "Hidden"
            
            self.addSubview(privateLabel!)
            self.addSubview(privateLock!)
        }
    }
    
    func setupCell (withPost post:StoryItem) {
        
        self.post = post
        
        check += 1
        self.imageView.image = nil
        self.nameLabel.text = ""
        self.timeLabel.text = ""
        
        self.firstIcon.isHidden = false
        self.firstLabel.isHidden = false
        self.secondIcon.isHidden = false
        self.secondLabel.isHidden = false
        self.timeLabel.isHidden = true
        self.timeLabel.text = post.dateCreated.timeStringSinceNow()
        
        self.imageView.image = nil
        
        let numLikes = post.numLikes
        let numComments = post.numComments
        
        let likesImage = UIImage(named: "liked")
        let commentsImage = UIImage(named: "comments_filled")
        if numLikes > 0 {
            self.firstLabel.text = getNumericShortesthandString(numLikes)
            self.firstIcon.image = likesImage
            self.firstIcon.isHidden = false
            self.firstLabel.isHidden = false
            
            self.secondLabel.text = getNumericShortesthandString(numComments)
            
            if numComments > 0 {
                self.secondIcon.image = commentsImage
                self.secondIcon.isHidden = false
                self.secondLabel.isHidden = false
                
            } else {
                self.secondIcon.image = nil
                self.secondIcon.isHidden = true
                self.secondLabel.isHidden = true
            }
        } else {
            self.firstLabel.text = getNumericShortesthandString(numComments)
            self.secondLabel.text = ""
            if numComments > 0 {
                self.firstIcon.image = commentsImage
                self.firstIcon.isHidden = false
                self.firstLabel.isHidden = false
            } else {
                self.firstIcon.image = nil
                self.firstIcon.isHidden = true
                self.firstLabel.isHidden = true
            }
            
            self.secondIcon.image = nil
            self.secondIcon.isHidden = true
            self.secondLabel.isHidden = true
        }
        
        
        self.colorView.isHidden = numLikes == 0 && numComments == 0 ? true : false
        self.gradient?.removeFromSuperlayer()
        
        
        //self.gradient!.drawsAsynchronously = true
        //self.colorView.layer.drawsAsynchronously = true

        guardView.isHidden = !post.shouldBlock
        
        UploadService.retrieveImage(withCheck: self.check, key: post.key, url: post.downloadUrl) { _check, image, fromFile in

                if self.check != _check { return }
                
                self.imageView.image = image
            
                if let color = post.getColor(), !self.colorView.isHidden {
                    self.gradient = CAGradientLayer()
                    self.gradient!.frame = self.colorView.bounds
                    self.gradient!.locations = [0.0, 1.0]
                    self.gradient!.startPoint = CGPoint(x: 0, y: 0)
                    self.gradient!.endPoint = CGPoint(x: 0, y: 1)
                    self.gradient!.shouldRasterize = false
                    self.colorView.layer.shouldRasterize = false
                    self.gradient!.colors = [UIColor.clear.cgColor, color.withAlphaComponent(0.75).cgColor]
                    self.colorView.layer.insertSublayer(self.gradient!, at: 0)
                    self.colorView.alpha = photoCellColorAlpha
                }

        }
        
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
                UploadService.retrieveImage(byKey: item!.key, withUrl: item!.downloadUrl, completion: { image, fromFile in
                    self.colorView.alpha = photoCellColorAlpha
                    completion(check, item!, image, fromFile)
                })
            } else {
            }
        })
    }
    
    func getImage(withCheck check: Int, post:StoryItem, completion: @escaping ((_ check:Int, _ image:UIImage?, _ fromFile:Bool)->())) {
        UploadService.retrieveImage(byKey: post.key, withUrl: post.downloadUrl, completion: { image, fromFile in
            completion(check, image, fromFile)
        })
    }
    
    func getUser(withCheck check: Int, uid:String, completion: @escaping ((_ check:Int, _ user:User?)->())) {
        UserService.getUser(uid, completion: { user in
            completion(check, user)
        })
    }
    
    
    func fadeInInfo(animated:Bool) {
        if animated {
            self.colorView.alpha = 0.0
            self.overlay.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.colorView.alpha = photoCellColorAlpha
                self.overlay.alpha = 1.0
            })
        } else {
            self.colorView.alpha = photoCellColorAlpha
            self.overlay.alpha = 1.0
        }
    }
    
    func fadeOutInfo() {
        self.colorView.alpha = 0.0
        self.overlay.alpha = 0.0
    }

}
