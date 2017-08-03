//
//  StoryInfoView.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-07.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import ActiveLabel

protocol PostCaptionProtocol: class {
    func showAuthor()
}

class StoryInfoView: UIView {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var captionLabel: ActiveLabel!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var usernameTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var verifiedBadge: UIImageView!
    
    @IBOutlet weak var pinImage: UIImageView!
    
    weak var delegate:PostCaptionProtocol?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        usernameLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        captionLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        pinImage.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        pinImage.isHidden = true
        
        captionLabel.enabledTypes = [.mention]
        captionLabel.customColor[ActiveType.mention] = accentColor
        captionLabel.handleMentionTap { mention in
            
            let controller = UserProfileViewController()
            controller.username = mention
            globalMainInterfaceProtocol?.navigationPush(withController: controller, animated: true)
        }
    }
    
    func setInfo(_ item:StoryItem) {

        self.userImageView.cropToCircle()
        
        if let anon = item.anon {
            self.verifiedBadge.image = nil
            self.userImageView.image = UIImage(named:anon.animal)
            self.captionLabel.text = item.caption
            self.usernameLabel.textColor = anon.color
            self.userImageView.backgroundColor = anon.color
            
            if let anonID = userState.anonID, anonID == item.authorId {
                self.usernameLabel.setAnonymousName(anonName: anon.anonName, color: anon.color, suffix: "[YOU]", fontSize: 14.0)
            } else {
                self.usernameLabel.text = anon.anonName
            }
            
            UploadService.retrieveAnonImage(withName: anon.animal) { image, fromFile in
                self.userImageView.image = image
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.authorTapped))
            self.userImageView.isUserInteractionEnabled = true
            self.userImageView.addGestureRecognizer(tap)
        } else {
            self.usernameLabel.textColor = UIColor.white
            self.userImageView.backgroundColor = UIColor(white: 1.0, alpha: 0.35)
            UserService.getUser(item.authorId, completion: { user in
                if user != nil {
                    //self.usernameLabel.setUsernameWithBadge(username: user!.username, badge: user!.badge, fontSize: 14.0, fontWeight: UIFontWeightMedium)
                    self.usernameLabel.text = user!.username
                    self.captionLabel.text = item.caption
                    if item.caption != "" {
                        self.usernameTopConstraint.constant = 8
                    } else {
                        self.usernameTopConstraint.constant = 16
                    }
                    
                    if user!.verified {
                        self.verifiedBadge.image = UIImage(named:"verified_white")
                    } else {
                        self.verifiedBadge.image = nil
                    }
                    self.userImageView.loadImageAsync(user!.imageURL, completion: nil)
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.authorTapped))
                    self.userImageView.isUserInteractionEnabled = true
                    self.userImageView.addGestureRecognizer(tap)
                }
            })
            
        }
        
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        delegate?.showAuthor()
    }
    
    
}
