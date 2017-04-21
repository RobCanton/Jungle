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
    }
    
    var location:Location!
    var moreHandler:(()->())?
    var showAuthorHandler:(()->())?
    
    
    func setup(withUser user:User, optionsHandler:(()->())?) {

        moreHandler = optionsHandler
        self.userImageView.image = nil
        self.userImageView.loadImageAsync(user.getImageUrl(), completion: { _ in })
        self.usernameLabel.text = user.getUsername()
        
        self.userImageView.cropToCircle()
        self.userImageView.superview!.applyShadow(radius: 2.0, opacity: 0.5, height: 1.0, shouldRasterize: false)
        self.usernameLabel.applyShadow(radius: 1.5, opacity: 0.35, height: 0.75, shouldRasterize: false)
        self.locationTitle.applyShadow(radius: 1.5, opacity: 0.35, height: 0.75, shouldRasterize: false)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tap2)
        
    }
    
    func userTapped(tap:UITapGestureRecognizer) {
        print("userTapped")
        showAuthorHandler?()
    }
    
    func setupLocation(location:Location) {
        locationTitle.text = location.getName()
    }
    
    @IBAction func moreTapped(_ sender: UIButton) {
        moreHandler?()
    }
    
    
   }
