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

    @IBOutlet weak var messageButton: UIButton!
    
    @IBOutlet weak var followButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        print("I'm awake, i'm awake")
 
    }
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var followingLabel: UILabel!
    
    
    func setupHeader(_user:User?) {
        
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        
        followButton.layer.cornerRadius = 2.0
        followButton.clipsToBounds = true
        followButton.backgroundColor = UIColor(red: 0.0, green: 128/255, blue: 255/255, alpha: 1.0)
        
        messageButton.layer.cornerRadius = 2.0
        messageButton.clipsToBounds = true
        messageButton.backgroundColor = UIColor(red: 0.0, green: 128/255, blue: 255/255, alpha: 1.0)
        
        guard let user = _user else {return}
        
        imageView.loadImageAsync(user.getImageUrl(), completion: { fromFile in })
        
        postsLabel.styleProfileBlockText(count: 41245, text: "posts", color: UIColor.gray, color2: UIColor.black)
        
        followersLabel.styleProfileBlockText(count: 124, text: "followers", color: UIColor.gray, color2: UIColor.black)
        
        followingLabel.styleProfileBlockText(count: 235235, text: "following", color: UIColor.gray, color2: UIColor.black)
    }

}
