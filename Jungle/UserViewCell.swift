
//
//  UserViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class UserViewCell: UITableViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var followButton: UIButton!
    
    @IBOutlet weak var verifiedBadge: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentImageView.cropToCircle()
        
        followButton.layer.cornerRadius = 4.0
        followButton.clipsToBounds = true
        followButton.layer.borderWidth = 1.0
        followButton.isHidden = false    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var user:User?
    
    var status:FollowingStatus?
    
    func setupUser(uid:String) {
        contentImageView.image = nil
        
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.user = user!
                self.contentImageView.loadImageAsync(user!.getImageUrl(), completion: nil)
                self.usernameLabel.text = user!.getUsername()      
            }
        })
        
        if mainStore.state.socialState.blockedBy.contains(uid) {
            followButton.isHidden = true
        } else {
            setUserStatus(status: checkFollowingStatus(uid: uid))
        }
    }
    
    func clearMode(_ enabled:Bool) {
        if enabled {
            self.backgroundColor = UIColor.clear
            self.contentView.backgroundColor = UIColor.clear
            self.usernameLabel.textColor = UIColor.white
            followButtonColor = UIColor.white
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.clear
            self.selectedBackgroundView = backgroundView
        } else {
            self.backgroundColor = UIColor.white
            self.contentView.backgroundColor = UIColor.white
            self.usernameLabel.textColor = UIColor.black
            followButtonColor = UIColor.black
        }
    }
    
    var followButtonColor = UIColor.black
    
    func setUserStatus(status:FollowingStatus) {
        if self.status == status { return }
        self.status = status
        
        switch status {
        case .CurrentUser:
            followButton.isHidden = true
            break
        case .None:
            followButton.isHidden = false
            followButton.backgroundColor = accentColor
            followButton.layer.borderColor = UIColor.clear.cgColor
            followButton.setTitle("Follow", for: .normal)
            followButton.setTitleColor(UIColor.white, for: .normal)
            break
        case .Requested:
            followButton.isHidden = false
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = followButtonColor.cgColor
            followButton.setTitle("Requested", for: .normal)
            followButton.setTitleColor(followButtonColor, for: .normal)
            break
        case .Following:
            followButton.isHidden = false
            followButton.backgroundColor = UIColor.clear
            followButton.layer.borderColor = followButtonColor.cgColor
            followButton.setTitleColor(followButtonColor, for: .normal)
            followButton.setTitle("Following", for: .normal)
            break
        }
    }
    
    
    var followHandler:(()->())?
    
    var unfollowHandler:((_ user:User)->())?
    
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }
        print("SUH DUDE")
        switch status {
        case .CurrentUser:
            break
        case .Following:
            unfollowHandler?(user)
            break
        case .None:
            if mainStore.state.socialState.blockedBy.contains(user.getUserId()) { return }
            setUserStatus(status: .Requested)
            UserService.followUser(uid: user.getUserId())
            followHandler?()
            break
        case .Requested:
            break
        }
    }
    
}
