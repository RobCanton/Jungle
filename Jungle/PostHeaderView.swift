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
    var moreHandler:(()->())?
    
    func setup(_ location:Location, optionsHandler:(()->())?) {
        self.location = location
        moreHandler = optionsHandler
        locationTitle.text = location.getName()
        timeLabel.text = location.getShortAddress()
    }
    
    func setup(withPlaceId id:String, optionsHandler:(()->())?) {
        moreHandler = optionsHandler
        LocationService.sharedInstance.getLocationInfo(id, completion: { location in
            if location != nil {
                self.locationTitle.text = location!.getName()
                self.timeLabel.text = location!.getShortAddress()
            }
        })
    }
    
    @IBAction func moreTapped(_ sender: UIButton) {
        moreHandler?()
    }
    
    
   }
