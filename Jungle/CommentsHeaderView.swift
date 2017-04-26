//
//  CommentsHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsHeaderView: UIView {
    
    @IBOutlet weak var viewsLabel: UILabel!
    
    @IBOutlet weak var commentsLabel: UILabel!

    @IBOutlet weak var rightButton: UIButton!

    var closeHandler:(()->())?
    var moreHandler:(()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    @IBAction func handleClose(_ sender: Any) {
        closeHandler?()
    }
    
    @IBAction func handleMore(_ sender: Any) {
        moreHandler?()
    }
    
    func setUserInfo(uid:String) {
       
        
        if uid == mainStore.state.userState.uid {
            rightButton.setImage(UIImage(named:"trash"), for: .normal)
        } else {
            rightButton.setImage(UIImage(named:"more"), for: .normal)
        }
    }
    
    func setViewsLabel(count:Int) {
        self.viewsLabel.text = "\(count)"
    }
    
    
    func setCommentsLabel(count:Int) {
        self.commentsLabel.text = "\(count)"
    }
    
    
}
