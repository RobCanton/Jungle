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
    
    @IBOutlet weak var block: UIView!
    
    @IBOutlet weak var commentsLabel: UILabel!
    
    var pullUpTapHandler:(()->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(blockTapped))
        block.isUserInteractionEnabled = true
        block.addGestureRecognizer(tap)
    }

    func blockTapped() {
        print("YEA")
        pullUpTapHandler?()
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
