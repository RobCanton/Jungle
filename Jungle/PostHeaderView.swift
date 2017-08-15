//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit


protocol PostHeaderProtocol: class {
    func showAuthor()
    func showPlace(_ location:Location)
    func showRegion(_ region:City)
    func showMetaLikes()
    func showMetaComments(_ indexPath:IndexPath?)
    func dismiss()
}

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationTitle: UILabel!
    
    @IBOutlet weak var likesIcon: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsIcon: UIImageView!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var badgeView: UIImageView!
    
    var commentsTap:UITapGestureRecognizer?
    var likesTap:UITapGestureRecognizer?
    
    weak var itemRef:StoryItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImageView.cropToCircle()
        
    }
    
    var gradient:CAGradientLayer?
    
    weak var delegate:PostHeaderProtocol?
    var tap:UITapGestureRecognizer?
    var tap2:UITapGestureRecognizer?
    var placeTap:UITapGestureRecognizer!
    
    func setup(_ item:StoryItem) {

        self.itemRef = item
        clean()
        
        setupLocation(locationKey: item.locationKey, regionKey: item.regionKey)
        setNumLikes(item.numLikes)
        setNumComments(item.numComments)
        
        //usernameLabel.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        //timeLabel2.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        //locationTitle.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        
        if let anon = item.anon {
            if isCurrentUserId(id: item.authorId) {
                self.usernameLabel.setAnonymousName(anonName: anon.anonName, color: anon.color, suffix: "[YOU]", fontSize: 16.0)//.usernameLabel.text = "\(anon.anonName) (YOU)"
            } else {
                self.usernameLabel.text = anon.anonName
                self.usernameLabel.textColor = anon.color
                 self.usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
            }
            
           
            UploadService.retrieveAnonImage(withName: anon.animal) { image, fromFile in
                self.userImageView.image = image
            }
            self.userImageView.backgroundColor = anon.color
            self.timeLabel2.text = item.dateCreated.timeStringSinceNow()
            self.badgeView.image = nil
        } else {
            self.usernameLabel.text = "Loading..."
            UserService.getUser(item.authorId, completion: { _user in
                guard let user = _user else { return }
                self.userImageView.loadImageAsync(user.imageURL, completion: { _ in })
                self.userImageView.backgroundColor = UIColor(white: 1.0, alpha: 0.35)
                self.usernameLabel.setUsernameWithBadge(username: user.username, badge: user.badge, fontSize: 16.0, fontWeight: UIFontWeightSemibold)
                self.usernameLabel.textColor = UIColor.white
                self.timeLabel2.text = item.dateCreated.timeStringSinceNow()
                
                if user.verified {
                    self.badgeView.image = UIImage(named: "verified_white")
                } else {
                    self.badgeView.image = nil
                }
                
            })
        }
        
        
        tap = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(tap!)
        tap2 = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tap2!)
        
        likesTap = UITapGestureRecognizer(target: self, action: #selector(self.likesTapped))
        likesIcon.superview!.isUserInteractionEnabled = true
        likesIcon.superview!.addGestureRecognizer(likesTap!)
        
        commentsTap = UITapGestureRecognizer(target: self, action: #selector(self.commentsTapped))
        commentsIcon.superview!.isUserInteractionEnabled = true
        commentsIcon.superview!.addGestureRecognizer(commentsTap!)
        
        placeTap = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
        locationTitle.isUserInteractionEnabled = true
        locationTitle.addGestureRecognizer(placeTap)
        

    }
    
    func setNumLikes(_ numLikes:Int) {
        likesLabel.text = getNumericShorthandString(numLikes)
    }
    
    func setNumComments(_ numComments:Int) {
        
        commentsLabel.text = getNumericShorthandString(numComments)
    }
    
    @IBOutlet weak var timeLabel2: UILabel!
    
    
    func likesTapped() {
        delegate?.showMetaLikes()
    }
    func commentsTapped() {
        delegate?.showMetaComments(nil)
    }
    
    
    func clean() {
        self.userImageView.image = nil
        self.usernameLabel.text = ""
        self.timeLabel2.text = ""
        if tap != nil {
            self.userImageView.removeGestureRecognizer(tap!)
        }
        if tap2 != nil {
            self.usernameLabel.removeGestureRecognizer(tap2!)
        }
        locationTitle.text = ""
        
    }
    
    func userTapped(tap:UITapGestureRecognizer) {
        delegate?.showAuthor()
    }
    
    var locationKey:String = ""
    var regionKey:String = ""

    weak var location:Location?
    weak var region:City?
    
    func setupLocation(locationKey:String?, regionKey:String?) {
        clearLocation()
        if locationKey != nil {
            self.locationKey = locationKey!
            locationTitle.text = " · Loading..."
            LocationService.sharedInstance.getLocationInfo(withReturnKey: locationKey!) { key, _location in
                if self.locationKey != key { return }
                self.location = _location
                if let location = _location {
                    self.locationTitle.text = " · \(location.name)"
                } else {
                    self.locationTitle.text = nil
                }
            }
        } else if regionKey != nil {
            self.regionKey = regionKey!
            locationTitle.text = " · Loading..."
            LocationService.sharedInstance.getRegionInfo(withReturnKey: regionKey!) { key, _region in
                if self.regionKey != key { return }
                self.region = _region
                if let region = _region {
                    self.locationTitle.text = " · \(region.name)"
                } else {
                    self.locationTitle.text = nil
                }
            }
        }
        
    }
    
    
    func clearLocation() {
        locationTitle.text = nil
        location = nil
        region = nil
    }
    
    func locationTapped(tap:UITapGestureRecognizer) {
        
        if let loc = self.location {
            delegate?.showPlace(loc)
        } else if let region = self.region {
            delegate?.showRegion(region)
        }

    }
    

    
}
