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
    @IBOutlet weak var captionLeading: NSLayoutConstraint!
    @IBOutlet weak var captionBottom: NSLayoutConstraint!
    @IBOutlet weak var captionTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var firstIconWidth: NSLayoutConstraint!
    @IBOutlet weak var secondIconWidth: NSLayoutConstraint!
    
    var location:Location!
    var gradient:CAGradientLayer?
    var largeGradient:CAGradientLayer?
    
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
    
    func setCrownStatus(index:Int) {
        
        
        if index == 0 {
            crown.isHidden = false
            crownLabel.isHidden = true
            
            self.crown.applyShadow(radius: 8.0, opacity: 1.0, height: 0.0, shouldRasterize: false)
            self.crown.layer.shadowColor = UIColor.clear.cgColor

        } else {
            crownLabel.isHidden = true
            crown.isHidden = true
        }
        
        if index % 3 == 0 {
            
            captionLabel.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightSemibold)
            captionLabel.numberOfLines = 3
            
            self.gradient?.removeFromSuperlayer()
            //self.colorView.isHidden = numLikes == 0 && numComments == 0 ? true : false
            self.largeGradient?.removeFromSuperlayer()
            self.largeGradient = CAGradientLayer()
            self.largeGradient!.frame = CGRect(x: 0, y: -80, width: UIScreen.main.bounds.width * 2 / 3, height: 320)
            self.largeGradient!.locations = [0.0, 1.0]
            self.largeGradient!.startPoint = CGPoint(x: 0, y: 0)
            self.largeGradient!.endPoint = CGPoint(x: 0, y: 1)
            self.largeGradient!.shouldRasterize = false
            self.largeGradient!.isHidden = false
            
            self.timeLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)
            self.firstLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)
            self.secondLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightMedium)
            
            self.firstIconWidth.constant = 12
            self.secondIconWidth.constant = 12
            
            if let post = post, let color = post.getColor(), !self.colorView.isHidden {
                self.largeGradient!.colors = [UIColor.clear.cgColor, color.withAlphaComponent(1.0).cgColor]
                self.colorView.alpha = 1.0
                self.crown.layer.shadowColor = color.cgColor
                captionBottom.constant = post.numLikes == 0 && post.numLikes == 0 ? 4 : 24
            }
            self.colorView.layer.shouldRasterize = false
            self.colorView.layer.insertSublayer(self.largeGradient!, at: 0)
        } else {
            
            self.largeGradient?.isHidden = true
            self.largeGradient?.removeFromSuperlayer()

            captionLabel.font = UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightMedium)
            captionLabel.numberOfLines = 2
            
            self.timeLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
            self.firstLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
            self.secondLabel.font = UIFont.systemFont(ofSize: 11.0, weight: UIFontWeightRegular)
            
            self.firstIconWidth.constant = 9
            self.secondIconWidth.constant = 9
            if let post = post {
                captionBottom.constant = post.numLikes == 0 && post.numComments == 0 ? 4 : 20
            }
        }

    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradient?.frame = self.colorView.bounds
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer === gradient {
            layer.frame = self.colorView.bounds
        }
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.gradient?.frame = self.colorView.bounds
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
        
        self.timeLabel.text = nil//post.dateCreated.timeStringSinceNow()
        
        let numLikes = post.numLikes
        let numComments = post.numComments
        
        let likesImage = UIImage(named: "liked")
        let commentsImage = UIImage(named: "comments_filled")
        
        captionBottom.constant = numLikes == 0 && numComments == 0 ? 4 : 20
        
        self.colorView.isHidden = numLikes == 0 && numComments == 0 && (post.caption == nil || post.caption == "") ? true : false
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
        self.captionLabel.text = nil
        self.firstLabel.text = nil
        self.firstIcon.image = nil
        self.secondLabel.text = nil
        self.secondIcon.image = nil
        
        UploadService.retrieveImage(withCheck: self.check, key: post.key, url: post.downloadUrl) { _check, image, fromFile in

            if self.check != _check { return }
            
            if fromFile {
                self.imageView.alpha = 1.0
            } else {
                self.imageView.alpha = 0.0
                UIView.animate(withDuration: 0.15, animations: {
                    self.imageView.alpha = 1.0
                })
            }
            
            self.imageView.image = image
            self.captionLabel.text = post.caption
            
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
                self.secondLabel.text = nil
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
            self.largeGradient?.isHidden = false
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
