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
    
}
