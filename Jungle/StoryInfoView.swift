//
//  StoryInfoView.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-07.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class StoryInfoView: UIView {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var usernameTopConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var pinImage: UIImageView!
    
    var uid:String?
     var authorTappedHandler:((_ uid:String)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //backgroundBlur.isHidden = true
        //backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        
        usernameLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        captionLabel.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
        pinImage.applyShadow(radius: 0.25, opacity: 0.5, height: 0.25, shouldRasterize: true)
    }
    
    func setInfo(user:User, item:StoryItem) {
        uid = user.getUserId()
        usernameLabel.text = user.getDisplayName()
        captionLabel.text = item.caption
        if item.caption != "" {
            usernameTopConstraint.constant = 8
        } else {
            usernameTopConstraint.constant = 16
        }
    }
    
    func setUserImage(image:UIImage) {
        userImageView.image = image
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
        userImageView.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tap)
    }
    
    func authorTapped(gesture:UITapGestureRecognizer) {
        if uid != nil {
            authorTappedHandler?(uid!)
        }
    }
    
    func phaseInCaption() {

    }
    
}
