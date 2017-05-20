//
//  ProfileHeaderView.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-21.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

protocol ProfileHeaderProtocol {
    func showFollowers()
    func showFollowing()
    func showConversation()
    func showEditProfile()
    func changeFollowStatus()
}

class ProfileHeaderView: UICollectionReusableView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    var delegate:ProfileHeaderProtocol?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("I'm awake, i'm awake")
        followButton.backgroundColor = accentColor
        messageButton.backgroundColor = accentColor
        editProfileButton.setTitleColor(UIColor.black, for: .normal)
        editProfileButton.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        followButton.isHidden = true
        messageButton.isHidden = true
        editProfileButton.isHidden = true
        
        postsLabel.styleProfileBlockText(count: 0, text: "posts", color: UIColor.gray, color2: UIColor.clear)
        followersLabel.styleProfileBlockText(count: 0, text: "followers", color: UIColor.gray, color2: UIColor.clear)
        followingLabel.styleProfileBlockText(count: 0, text: "following", color: UIColor.gray, color2: UIColor.clear)
    }
    
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    

    
    var followersTapped:UITapGestureRecognizer!
    var followingTapped:UITapGestureRecognizer!
    var user:User?
    
    func setupHeader(_user:User?, status: FollowingStatus, delegate: ProfileHeaderProtocol) {
        self.delegate = delegate

        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        
        followButton.layer.cornerRadius = followButton.frame.height/2.0
        followButton.clipsToBounds = true
        followButton.tintColor = UIColor.white
        
        messageButton.layer.cornerRadius = messageButton.frame.height/2.0
        messageButton.clipsToBounds = true
        
        editProfileButton.layer.cornerRadius = editProfileButton.frame.height/2.0
        editProfileButton.clipsToBounds = true

        guard let user = _user else {return}
        self.user = _user
        setUserStatus(status: checkFollowingStatus(uid: user.getUserId()))
        
        setFollowersCount(user.followers)
        setFollowingCount(user.following)
        usernameLabel.text = user.getUsername()
        
        bioLabel.text = user.getBio()
        
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromFile in
            self.imageView.image = image
        })
        
        followersTapped = UITapGestureRecognizer(target: self, action: #selector(followersTappedHandler))
        followersLabel.isUserInteractionEnabled = true
        followersLabel.addGestureRecognizer(followersTapped)
        
        followingTapped = UITapGestureRecognizer(target: self, action: #selector(followingTappedHandler))
        followingLabel.isUserInteractionEnabled = true
        followingLabel.addGestureRecognizer(followingTapped)
    
    }
    
    func followersTappedHandler() {
        delegate?.showFollowers()
    }
    
    func followingTappedHandler() {
        delegate?.showFollowing()
    }
    
    @IBAction func handleFollowButton(_ sender: UIButton) {
        
        sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            sender.transform = CGAffineTransform.identity
        }, completion: nil)
        
        delegate?.changeFollowStatus()
    }
    
    @IBAction func buttonTouchCancel(_ sender: UIButton) {
        sender.transform = CGAffineTransform.identity
    }
    
    @IBAction func buttonTouchDown(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
    }
    
    @IBAction func buttonTouchUpInside(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            sender.transform = CGAffineTransform.identity
        }, completion: nil)
        
        switch sender {
        case followButton:
            delegate?.changeFollowStatus()
            break
        case messageButton:
            delegate?.showConversation()
            break
        case editProfileButton:
            delegate?.showEditProfile()
            break
        default:
            break
        }
    }
    
    
    @IBAction func handleEditButtonTouchUpInside(_ sender: Any) {
        delegate?.showEditProfile()
    }
    
    func setUserStatus(status:FollowingStatus) {
        switch status {
        case .CurrentUser:
            followButton.backgroundColor = UIColor.white
            followButton.isHidden = true
            messageButton.isHidden = true
            editProfileButton.isHidden = false
            break
        case .None:
            followButton.backgroundColor = accentColor
            followButton.setTitle("Follow", for: .normal)
            followButton.setTitleColor(UIColor.white, for: .normal)
            followButton.isHidden = false
            messageButton.isHidden = false
            editProfileButton.isHidden = true
            break
        case .Requested:
            followButton.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
            followButton.setTitle("Requested", for: .normal)
            followButton.setTitleColor(UIColor.black, for: .normal)
            followButton.isHidden = false
            messageButton.isHidden = false
            editProfileButton.isHidden = true
            break
        case .Following:
            followButton.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
            followButton.setTitle("Following", for: .normal)
            followButton.setTitleColor(UIColor.black, for: .normal)
            followButton.isHidden = false
            messageButton.isHidden = false
            editProfileButton.isHidden = true
            break
        }
 
    }
    
    
    func setPostsCount(_ count:Int) {
        if count == 1 {
            postsLabel.styleProfileBlockText(count: count, text: "post", color: UIColor.gray, color2: UIColor.black)
            
        } else {
            postsLabel.styleProfileBlockText(count: count, text: "posts", color: UIColor.gray, color2: UIColor.black)
        }
    }
    
    
    func setFollowersCount(_ count:Int) {
        if count == 1 {
            followersLabel.styleProfileBlockText(count: count, text: "follower", color: UIColor.gray, color2: UIColor.black)

        } else {
            followersLabel.styleProfileBlockText(count: count, text: "followers", color: UIColor.gray, color2: UIColor.black)
        }
    }
    
    func setFollowingCount(_ count:Int) {
        followingLabel.styleProfileBlockText(count: count, text: "following", color: UIColor.gray, color2: UIColor.black)
    }
    
    

}
