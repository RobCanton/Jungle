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

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var firstIcon: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    
    @IBOutlet weak var secondIcon: UIImageView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var crown: UIImageView!
    @IBOutlet weak var crownLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
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
        
    }
    
    func setCrownStatus(isKing:Bool) {
        crown.isHidden = !isKing
        
        crownLabel.isHidden = true//!isKing
        firstIcon.isHidden = isKing
        firstLabel.isHidden = isKing
        secondIcon.isHidden = isKing
        secondLabel.isHidden = isKing
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

        
        self.firstIcon.isHidden = false
        self.firstLabel.isHidden = false
        self.secondIcon.isHidden = false
        self.secondLabel.isHidden = false
        
        self.imageView.image = nil
        
        self.timeLabel.text = nil //post.dateCreated.timeStringSinceNow()
        
        let numLikes = post.numLikes
        let numComments = post.numComments
        
        let likesImage = UIImage(named: "liked")
        let commentsImage = UIImage(named: "comments_filled")
        
        if numComments > 0 {
            self.secondLabel.text = getNumericShorthandString(numComments)
            self.secondIcon.image = commentsImage
            self.secondIcon.isHidden = false
            self.secondLabel.isHidden = false
            
        
            if numLikes > 0 {
                self.firstLabel.text = getNumericShorthandString(numLikes)
                self.firstIcon.image = likesImage
                self.firstIcon.isHidden = false
                self.firstLabel.isHidden = false
            } else {
                self.firstLabel.text = nil
                self.firstIcon.image = nil
                self.firstIcon.isHidden = true
                self.firstLabel.isHidden = true
            }
        } else {
            self.firstLabel.text = nil
            self.firstIcon.image = nil
            self.firstIcon.isHidden = true
            self.firstLabel.isHidden = true
            
            if numLikes > 0 {
                self.secondLabel.text = getNumericShorthandString(numLikes)
                self.secondIcon.image = likesImage
                self.secondIcon.isHidden = false
                self.secondLabel.isHidden = false
            } else {
                self.secondLabel.text = nil
                self.secondIcon.image = nil
                self.secondIcon.isHidden = true
                self.secondLabel.isHidden = true
            }
            
        }
        
        //self.colorView.isHidden = numLikes == 0 && numComments == 0 ? true : false
        self.gradient?.removeFromSuperlayer()
        self.gradient = CAGradientLayer()
        self.gradient!.frame = self.colorView.bounds
        self.gradient!.locations = [0.0, 1.0]
        self.gradient!.startPoint = CGPoint(x: 0, y: 0)
        self.gradient!.endPoint = CGPoint(x: 0, y: 1)
        self.gradient!.shouldRasterize = false
        self.colorView.layer.shouldRasterize = false
        self.colorView.layer.insertSublayer(self.gradient!, at: 0)
        
        //self.gradient!.drawsAsynchronously = true
        //self.colorView.layer.drawsAsynchronously = true

        guardView.isHidden = !post.shouldBlock
        captionLabel.text = post.caption
        
        
        UploadService.retrieveImage(withCheck: self.check, key: post.key, url: post.downloadUrl) { _check, image, fromFile in

            if self.check != _check { return }
                
            self.imageView.image = image
            
            if let color = post.getColor(), !self.colorView.isHidden {
                self.gradient!.colors = [UIColor.clear.cgColor, color.withAlphaComponent(0.82).cgColor]
                self.colorView.alpha = photoCellColorAlpha
            }
            
            self.captionLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
            self.timeLabel.applyShadow(radius: 3, opacity: 0.90, height: 1.0, shouldRasterize: true)
            self.firstIcon.applyShadow(radius: 5, opacity: 0.6, height: 0.0, shouldRasterize: true)
            self.firstLabel.applyShadow(radius: 5, opacity: 0.6, height: 0.0, shouldRasterize: true)
            self.secondIcon.applyShadow(radius: 5, opacity: 0.6, height: 0.0, shouldRasterize: true)
            self.secondLabel.applyShadow(radius: 3, opacity: 0.6, height: 0.0, shouldRasterize: true)
            self.crown.applyShadow(radius: 5.0, opacity: 0.6, height: 0.0, shouldRasterize: true)
        }
        
    }
    
    
    func setupUserCell (_ post:StoryItem) {
        
        check += 1
        self.imageView.image = nil

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
