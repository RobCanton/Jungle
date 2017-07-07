//
//  NotificationBadgeCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-04.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class NotificationBadgeCell: UITableViewCell {

    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setLabel( date: Date) {
        let timeStr = " \(date.timeStringSinceNow())"
        var message = "You've unlocked a new badge!"
        
        let str = "\(message)\(timeStr)"
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1

        
        let a2: [String: AnyObject] = [
            NSForegroundColorAttributeName : UIColor(white: 0.67, alpha: 1.0)
        ]
        title.addAttributes(a2, range: NSRange(location: message.characters.count, length: timeStr.characters.count))
        
        label.attributedText = title
    }
}
