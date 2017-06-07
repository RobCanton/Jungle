

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
        if(selected)  {
            contentView.backgroundColor = UIColor.red
        } else {
            contentView.backgroundColor = UIColor.white
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if(highlighted) {
            contentView.backgroundColor = UIColor.red
        } else {
            contentView.backgroundColor = UIColor.white
        }
    }
    var key = ""
    private(set) var isActive = false
    func toggleSelection(_ selected: Bool) {
        isActive = selected
        if selected {
            bgView.backgroundColor = UIColor.white
            circleButton.setImage(UIImage(named: "check_2"), for: .normal)
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
            circleButton.layer.borderColor = UIColor(white: 0.92, alpha: 1.0).cgColor
            circleButton.layer.borderWidth = 1.0
            
        }
    }
    var user:User?
    
    func setTextBold(_ bold:Bool) {
        if bold {
            label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightBold)
        } else {
            label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
        }
    }
    
    func setupUser(uid:String) {
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.user = user!
                self.label.text = user!.username
                self.subtitle.text = "Robert Canton"
            }
        })

    }

    
}
