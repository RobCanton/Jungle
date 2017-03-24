//
//  CommentsHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    var closeHandler:(()->())?
    var moreHandler:(()->())?

    @IBAction func handleClose(_ sender: Any) {
        closeHandler?()
    }
    
    @IBAction func handleMore(_ sender: Any) {
        moreHandler?()
    }
    
    func setUserInfo(uid:String) {
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.imageView.loadImageAsync(user!.getImageUrl(), completion: { result in })
                self.usernameLabel.text = "\(user!.getUsername())'s post"
                
            }
        })
    }
}
