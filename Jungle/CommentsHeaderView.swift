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
    
    var setMode:((_ mode:PostInfoMode)->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let viewsTap = UITapGestureRecognizer(target: self, action: #selector(viewsTapped))
        viewsLabel.superview?.isUserInteractionEnabled = true
        viewsLabel.superview?.addGestureRecognizer(viewsTap)
        
        let commentsTap = UITapGestureRecognizer(target: self, action: #selector(commentsTapped))
        commentsLabel.superview?.isUserInteractionEnabled = true
        commentsLabel.superview?.addGestureRecognizer(commentsTap)
    }
    
    func viewsTapped() {
        setMode?(.Viewers)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.viewsLabel.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.viewsLabel.alpha = 1.0
            }, completion: { _ in
                
            })
        })
    }
    
    func commentsTapped() {
        setMode?(.Comments)
        
        UIView.animate(withDuration: 0.025, animations: {
            self.commentsLabel.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.25, animations: {
                self.commentsLabel.alpha = 1.0
            }, completion: { _ in
                
            })
        })
    }
    
    func setCurrentUserMode(_ isCurrentUser:Bool) {
        if isCurrentUser {
            commentsLabel.superview!.isUserInteractionEnabled = true
            viewsLabel.superview!.isUserInteractionEnabled = true
        } else {
            commentsLabel.superview!.isUserInteractionEnabled = false
            viewsLabel.superview!.isUserInteractionEnabled = false
        }
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
