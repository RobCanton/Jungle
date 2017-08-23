//
//  EmptyMessagesView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-16.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class EmptyMessagesView: UITableViewHeaderFooterView {

    @IBOutlet weak var backView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backView.layer.cornerRadius = 8.0
        backView.clipsToBounds = true
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
