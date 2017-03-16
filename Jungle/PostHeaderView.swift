//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PostHeaderView: UIView {

    @IBOutlet weak var locationTitle: UILabel!

    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()


    }
    
    var location:Location!
    
    func setupLocation(_ location:Location) {
        self.location = location
        
        locationTitle.text = location.getName()
        timeLabel.text = location.getShortAddress()
    }
    
    
    
   }
