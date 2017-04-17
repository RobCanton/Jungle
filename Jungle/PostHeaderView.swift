//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationTitle: UILabel!
    //@IBOutlet weak var locationTitle: UILabel!

   // @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.userImageView.cropToCircle()
    }
    
    var location:Location!
    var moreHandler:(()->())?
    
    
    func setup(withUser user:User, optionsHandler:(()->())?) {

        moreHandler = optionsHandler
        self.userImageView.loadImageAsync(user.getImageUrl(), completion: { _ in })
        self.usernameLabel.text = user.getUsername()
    }
    
    func setupLocation(location:Location) {
        locationTitle.text = location.getName()
    }
    
    @IBAction func moreTapped(_ sender: UIButton) {
        moreHandler?()
    }
    
    
   }
