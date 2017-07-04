//
//  BadgeCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class BadgeCell: UICollectionViewCell {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        backView.layer.cornerRadius =  16.0
        backView.clipsToBounds = true
        backView.isHidden = true

    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        } set {
            if newValue && badge != nil && badge!.isAvailable {
                super.isSelected = true
                backView.isHidden = false
            } else {
                super.isSelected = false
                backView.isHidden = true
            }
        }
    }
    var badge:Badge?
    
    func setup(withBadge badge:Badge) {
        self.badge = badge
        if badge.isAvailable {
            label.text = badge.icon
            label.alpha = 1.0
        } else {
            label.text = "🔒"
            label.alpha = 0.67
        }
    }

}
