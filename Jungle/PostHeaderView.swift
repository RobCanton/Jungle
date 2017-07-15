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
    func showMetaLikes()
    func showMetaComments(_ indexPath:IndexPath?)
    func dismiss()
}

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var likesView: UIView!
    @IBOutlet weak var commentsView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var locationTitle: UILabel!
    
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var badgeView: UIImageView!
    
    var commentsTap:UITapGestureRecognizer?
    var likesTap:UITapGestureRecognizer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImageView.cropToCircle()
        
    }
    
    @IBAction func handleClose(_ sender: Any) {
            delegate?.dismiss()
    }
    
    weak var delegate:PostHeaderProtocol?
    var tap:UITapGestureRecognizer?
    var tap2:UITapGestureRecognizer?
    var placeTap:UITapGestureRecognizer?
    var placeTap2:UITapGestureRecognizer?
    
    func setup(_ item:StoryItem) {
        
        clean()
        
        setupLocation(locationKey: item.locationKey)
        setNumLikes(item.numLikes)
        setNumComments(item.numComments)
        
        if let anon = item.anon {
            if isCurrentUserId(id: item.authorId) {
                self.usernameLabel.setAnonymousName(anonName: anon.anonName, color: anon.color, suffix: "[YOU]", fontSize: 16.0)//.usernameLabel.text = "\(anon.anonName) (YOU)"
            } else {
                self.usernameLabel.text = anon.anonName
                self.usernameLabel.textColor = anon.color
                 self.usernameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
            }
            
           
            self.userImageView.image = UIImage(named:anon.animal)
            self.userImageView.backgroundColor = anon.color
            self.timeLabel2.text = item.dateCreated.timeStringSinceNow()
            self.badgeView.image = nil
        } else {
            
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
        self.likesView.isUserInteractionEnabled = true
        self.likesView.addGestureRecognizer(likesTap!)
        
        commentsTap = UITapGestureRecognizer(target: self, action: #selector(self.commentsTapped))
        self.commentsView.isUserInteractionEnabled = true
        self.commentsView.addGestureRecognizer(commentsTap!)
        
        //self.applyShadow(radius: 3.0, opacity: 0.5, height: 0.0, shouldRasterize: false)
        likesView.layer.cornerRadius = 3.0
        likesView.clipsToBounds = true
        
        commentsView.layer.cornerRadius = 3.0
        commentsView.clipsToBounds = true
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
    weak var location:Location?
    
    func setupLocation(locationKey:String?) {
        
        if locationKey != nil {
            self.locationKey = locationKey!
            locationTitle.text = " · Loading..."
            LocationService.sharedInstance.getLocationInfo(withReturnKey: locationKey!) { key, _location in
                if self.locationKey != key { return }
                self.locationRetrieved(_location)
            }
        } else {
            clearLocation()
        }
        
    }
    
    func locationRetrieved(_ location:Location?) {
        self.locationKey = ""
        self.location = location
        
        if location != nil {
            locationTitle.text = " · \(location!.name)"
            placeTap = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
            self.locationTitle.isUserInteractionEnabled = true
            self.locationTitle.addGestureRecognizer(placeTap!)
            placeTap2 = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
        } else {
            clearLocation()
        }
    }
    
    func clearLocation() {
        locationTitle.text = ""
        if placeTap != nil {
            self.locationTitle.removeGestureRecognizer(placeTap!)
            placeTap = nil
        }
        if placeTap2 != nil {
            placeTap2 = nil
        }
    }
    
    func locationTapped(tap:UITapGestureRecognizer) {
        guard let loc = self.location else { return }
        print("PRESENT LOCATION: \(loc.name)")
        delegate?.showPlace(loc)
    }
    

    
}
