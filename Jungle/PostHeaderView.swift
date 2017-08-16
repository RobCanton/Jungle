
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
    func showPostLikes()
    func showPostComments(_ indexPath:IndexPath?)

    func dismiss()
}

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationTitle: UILabel!
    

    @IBOutlet weak var badgeView: UIImageView!

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var viewsView: UIView!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var likesView: UIView!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsView: UIView!
    @IBOutlet weak var commentsLabel: UILabel!

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
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        
        stackView.addArrangedSubview(viewsView)
        stackView.addArrangedSubview(likesView)
        stackView.addArrangedSubview(commentsView)
        
        viewsView.isHidden = false
        likesView.isHidden = false
        commentsView.isHidden = false
        
        viewsView.isUserInteractionEnabled = true
        likesView.isUserInteractionEnabled = true
        commentsView.isUserInteractionEnabled = true
    }
    
    func setup(_ item:StoryItem) {

        self.itemRef = item
        clean()
        
        setupLocation(locationKey: item.locationKey, regionKey: item.regionKey)
        
        self.resetStack()
        
        let isCurrentUser = isCurrentUserId(id: item.authorId)
        
        let numViews = item.numViews
        let numLikes = item.numLikes
        let numComments = item.numComments
        
        viewsLabel.text = getNumericShorthandString(numViews)
        likesLabel.text = getNumericShorthandString(numLikes)
        commentsLabel.text = getNumericShorthandString(numComments)
        
        if numViews == 0 || !isCurrentUser {
            stackView.remove(view: viewsView)
        }
        
        if numLikes == 0 {
            stackView.remove(view: likesView)
        }
        
        if numComments == 0 {
            stackView.remove(view: commentsView)
        }
        
        //usernameLabel.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        //timeLabel2.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        //locationTitle.applyShadow(radius: 0.3, opacity: 0.65, height: 0.3, shouldRasterize: true)
        
        if let anon = item.anon {
            if isCurrentUser {
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
        
        placeTap = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
        locationTitle.isUserInteractionEnabled = true
        locationTitle.addGestureRecognizer(placeTap)
        
        let likesTap = UITapGestureRecognizer(target: self, action: #selector(self.showPostLikes))
        likesView.isUserInteractionEnabled = true
        likesView.addGestureRecognizer(likesTap)

        let commentsTap = UITapGestureRecognizer(target: self, action: #selector(self.showPostComments))
        commentsView.isUserInteractionEnabled = true
        commentsView.addGestureRecognizer(commentsTap)
    }
    
    func setNumLikes(_ numLikes:Int) {
        guard let item = itemRef else { return }
        self.resetStack()
        
        let isCurrentUser = isCurrentUserId(id: item.authorId)
        
        let numViews = item.numViews
        let numComments = item.numComments
        
        viewsLabel.text = getNumericShorthandString(numViews)
        likesLabel.text = getNumericShorthandString(numLikes)
        commentsLabel.text = getNumericShorthandString(numComments)
        
        if numViews == 0 ||  !isCurrentUser {
            stackView.remove(view: viewsView)
        }
        
        if numLikes == 0 {
            stackView.remove(view: likesView)
        }
        
        if numComments == 0 {
            stackView.remove(view: commentsView)
        }
        
    }
    
    func setNumComments(_ numComments:Int) {
        guard let item = itemRef else { return }
        self.resetStack()
        
        let isCurrentUser = isCurrentUserId(id: item.authorId)
        
        let numViews = item.numViews
        let numLikes = item.numLikes
        
        viewsLabel.text = getNumericShorthandString(numViews)
        likesLabel.text = getNumericShorthandString(numLikes)
        commentsLabel.text = getNumericShorthandString(numComments)
        
        if numViews == 0 ||  !isCurrentUser {
            stackView.remove(view: viewsView)
        }
        
        if numLikes == 0 {
            stackView.remove(view: likesView)
        }
        
        if numComments == 0 {
            stackView.remove(view: commentsView)
        }
    }
    
    @IBOutlet weak var timeLabel2: UILabel!
    
    func showPostLikes() {
        delegate?.showPostLikes()
    }
    
    func showPostComments() {
        delegate?.showPostComments(nil)
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
 
