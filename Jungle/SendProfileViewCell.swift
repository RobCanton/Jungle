

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
            bgView.backgroundColor = UIColor(red: 0.0, green: 128/255, blue: 1.0, alpha: 1.0)
            label.textColor = UIColor.white
            //circleButton.setImage(UIImage(named: "circle_checked"), for: .normal)
            //circleButton.tintColor = accentColor
        } else {
            bgView.backgroundColor = UIColor.white
            label.textColor = UIColor.black
            //circleButton.setImage(UIImage(named: "circle_unchecked"), for: .normal)
            //circleButton.tintColor = UIColor.gray
        }
    }
    
}
