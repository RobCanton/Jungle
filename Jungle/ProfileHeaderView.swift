//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProfileHeaderView: UICollectionReusableView {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var largeImageView: UIImageView!
    @IBOutlet weak var messageButton: UIButton!
    
    @IBOutlet weak var followButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        print("I'm awake, i'm awake")
        followButton.backgroundColor = UIColor.white
        messageButton.backgroundColor = UIColor.white//UIColor(red: 0.0, green: 128/255, blue: 255/255, alpha: 1.0)
        followButton.tintColor = accentColor
 
    }

    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var followingLabel: UILabel!
    
    var followHandler:(()->())?
    var messageHandler:(()->())?
    
    var status:FollowingStatus = .None
    var user:User?
    
    func setupHeader(_user:User?) {
        
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        
        let imageContainer = imageView.superview!
        imageContainer.applyShadow(radius: 1, opacity: 0.25, height: 1.0, shouldRasterize: false)
        
        followButton.layer.cornerRadius = followButton.frame.width/2.0
        followButton.clipsToBounds = true
        
        followButton.applyShadow(radius: 1, opacity: 0.25, height: 1.0, shouldRasterize: false)
        followButton.tintColor = UIColor.white
        
        messageButton.layer.cornerRadius = messageButton.frame.width/2.0
        messageButton.clipsToBounds = true
        
        messageButton.applyShadow(radius: 1, opacity: 0.25, height: 1.0, shouldRasterize: false)

        guard let user = _user else {return}
        self.user = _user
        
        
        
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromFile in
            self.imageView.image = image
            self.largeImageView.image = image
        })
        
        followersLabel.styleFollowerText(count: 1242, text: "followers", color: UIColor.darkGray, color2: UIColor.black)
        
        followingLabel.styleFollowerText(count: 42422, text: "following", color: UIColor.darkGray, color2: UIColor.black)
        
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor(white: 1.0, alpha: 0.5).cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradientView.layer.insertSublayer(gradient, at: 0)
        
        setUserStatus(status: checkFollowingStatus(uid: user.getUserId()))
    }
    
    
    @IBAction func handleFollowButton(_ sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.50, y: 0.50)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            sender.transform = CGAffineTransform.identity
        }, completion: nil)
        
        followHandler?()
        guard let user = self.user else { return }

        switch status {
        case .CurrentUser:
            break
        case .Following:
            UserService.unfollowUser(uid: user.getUserId())
            break
        case .None:
            setUserStatus(status: .Requested)
            UserService.followUser(uid: user.getUserId())
            break
        case .Requested:
            break
        }
    }
    
    @IBAction func messageButtonDown(_ sender: Any) {
        //messageButton.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
    }
    
    @IBAction func handleMessageButton(_ sender: Any) {
        messageButton.transform = CGAffineTransform(scaleX: 0.50, y: 0.50)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            self.messageButton.transform = CGAffineTransform.identity
        }, completion: nil)
        messageHandler?()
    }
    
    func setUserStatus(status:FollowingStatus) {
        
        self.status = status
        switch status {
        case .CurrentUser:
            followButton.backgroundColor = UIColor.white
            followButton.isHidden = true
            break
        case .None:
            followButton.backgroundColor = accentColor
            followButton.setImage(UIImage(named: "plus"), for: .normal)
            followButton.tintColor = UIColor.white
            followButton.isHidden = false
            break
        case .Requested:
            followButton.backgroundColor = UIColor.white
            followButton.setImage(UIImage(named: "plus"), for: .normal)
            followButton.tintColor = accentColor
            followButton.isHidden = false
            break
        case .Following:
            followButton.backgroundColor = UIColor.white
            followButton.setImage(UIImage(named: "check"), for: .normal)
            followButton.tintColor = accentColor
            followButton.isHidden = false
            break
        }
    }
    

}
