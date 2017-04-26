//
//  PostFooterView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-25.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class PostFooterView: UIView {
    
    @IBOutlet weak var commentsLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    func setCommentsLabelToCount(_ count:Int) {
        
        if count == 0 {
            commentsLabel.text = "COMMENT"
        } else if count == 1 {
            commentsLabel.text = "\(count) COMMENT"
        } else {
            commentsLabel.text = "\(count) COMMENTS"
        }
    
    }
}
