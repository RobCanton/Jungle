//
//  MyProfileViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class MyProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var postsLabel: UILabel!
    
    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var followingLabel: UILabel!
    
    
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        let uid = mainStore.state.userState.uid
        
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.setupUser(user: user!)
            }
        })
        
        editProfileButton.layer.borderColor = UIColor.white.cgColor
        editProfileButton.layer.borderWidth = 1.0
        
        editProfileButton.layer.cornerRadius = 4.0
        editProfileButton.clipsToBounds = true
        
        settingsButton.layer.borderColor = UIColor.white.cgColor
        settingsButton.layer.borderWidth = 1.0
        
        settingsButton.layer.cornerRadius = 4.0
        settingsButton.clipsToBounds = true
        
        
        
    }
    
    func setupUser(user:User) {
        profileImageView.loadImageAsync(user.getImageUrl(), completion: { fromFile in })
        
        usernameLabel.text = user.getUsername()
        
        postsLabel.styleProfileBlockText(count: 41245, text: "posts", color: UIColor.lightGray, color2: UIColor.white)
        
        followersLabel.styleProfileBlockText(count: 124, text: "followers", color: UIColor.lightGray, color2: UIColor.white)
        
        followingLabel.styleProfileBlockText(count: 235235, text: "following", color: UIColor.lightGray, color2: UIColor.white)
        
        
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
