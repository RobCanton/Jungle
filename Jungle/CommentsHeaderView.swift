//
//  CommentsHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsHeaderView: UIView {

    var closeHandler:(()->())?
    var moreHandler:(()->())?

    @IBAction func handleClose(_ sender: Any) {
        closeHandler?()
    }
    
    @IBAction func handleMore(_ sender: Any) {
        moreHandler?()
    }
}
