
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
    
    @IBOutlet weak var badgeView: UIImageView!
    
    var followButtonColor = UIColor.black
    
    weak var delegate:UserCellProtocol?
    
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
    var check:Int = 0
    var status:FollowingStatus?
    
    func setupAnon(_ anon:AnonObject) {
        status = nil
        check += 1
        self.contentImageView.backgroundColor = anon.color
        self.followButton.isHidden = true
        self.usernameLabel.text = anon.anonName
        self.usernameLabel.textColor = darkerColorForColor(color: anon.color)
        UploadService.retrieveAnonImage(withCheck: check, withName: anon.animal) { check, image, fromFile in
            if check == self.check {
                self.contentImageView.image = image
            }
        }
    }
    
    func setupUser(uid:String) {
        contentImageView.image = nil
        self.usernameLabel.textColor = UIColor.black
        self.followButton.isHidden = false
        check += 1
        
        UserService.getUser(withCheck: check, uid: uid) { check, user in
            if check != self.check { return }
            if user != nil {
                self.user = user!
                self.contentImageView.loadImageAsync(user!.imageURL, completion: nil)
                self.usernameLabel.setUsernameWithBadge(username: user!.username, badge: user!.badge, fontSize: 16.0, fontWeight: UIFontWeightMedium)
                
                if self.user!.verified {
                    self.badgeView.image = UIImage(named: "verified_white")
                } else {
                    self.badgeView.image = nil
                }
                
            }
        }
        

        setUserStatus(status: checkFollowingStatus(uid: uid))
    }
    
    func clearMode(_ enabled:Bool) {
        if enabled {
            self.backgroundColor = UIColor.clear
            self.contentView.backgroundColor = UIColor.clear
            self.usernameLabel.textColor = UIColor.white
            followButtonColor = UIColor.white
            followButton?.removeFromSuperview()
            
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
    
    func setUserStatus(status:FollowingStatus) {
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
    
    @IBAction func handleFollowTap(sender: AnyObject) {
        guard let user = self.user else { return }
        guard let status = self.status else { return }
        print("SUH DUDE")
        switch status {
        case .CurrentUser:
            break
        case .Following:
            delegate?.unfollowHandler(user)
            break
        case .None:
            setUserStatus(status: .Requested)
            UserService.followUser(uid: user.uid)
            break
        case .Requested:
            break
        }
    }
    
}
