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
    
    func setInfo(withUid uid:String, item:StoryItem, delegate: PostCaptionProtocol) {
        self.delegate = delegate
        
        self.userImageView.cropToCircle()
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.usernameLabel.text = user!.username
                self.captionLabel.text = item.caption
                if item.caption != "" {
                    self.usernameTopConstraint.constant = 8
                } else {
                    self.usernameTopConstraint.constant = 16
                }
                self.userImageView.loadImageAsync(user!.imageURL, completion: nil)
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.authorTapped))
                self.userImageView.isUserInteractionEnabled = true
                self.userImageView.addGestureRecognizer(tap)
            }
        })
        
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        delegate?.showAuthor()
    }
    
    
}
