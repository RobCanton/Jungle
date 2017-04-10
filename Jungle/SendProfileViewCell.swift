

//
//  SendProfileViewCell.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class SendProfileViewCell: UITableViewCell {
    
    @IBOutlet weak var circleButton: UIButton!

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    @IBOutlet weak var bgView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    var key = ""
    var isActive = false
    func toggleSelection(_ selected: Bool) {
        
        if selected {
            bgView.backgroundColor = UIColor.white
            circleButton.setImage(UIImage(named: "check"), for: .normal)
            circleButton.layer.cornerRadius = circleButton.frame.width / 2
            circleButton.backgroundColor = accentColor
            circleButton.clipsToBounds = true
            circleButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            bgView.backgroundColor = UIColor.white
            circleButton.setImage(UIImage(), for: .normal)
            circleButton.layer.cornerRadius = circleButton.frame.width / 2
            circleButton.clipsToBounds = true
            circleButton.backgroundColor = UIColor.clear
            circleButton.layer.borderColor = UIColor(white: 0.75, alpha: 1.0).cgColor
            circleButton.layer.borderWidth = 1.0
            
        }
    }
    
}
