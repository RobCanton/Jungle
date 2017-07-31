//
//  NoNearbyPostsHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class NoNearbyPostsHeaderView: UICollectionReusableView {

    @IBOutlet weak var grayView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    
        grayView.layer.cornerRadius = 6.0
        grayView.clipsToBounds = true
    }
    
    
    
}
