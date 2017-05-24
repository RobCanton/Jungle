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

    @IBOutlet weak var subscribeButton: UIButton!
    var subscribed:Bool?
    var postKey:String?
    
    weak var delegate: CommentsHeaderProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let viewsTap = UITapGestureRecognizer(target: self, action: #selector(viewsTapped))
        viewsLabel.superview?.isUserInteractionEnabled = true
        viewsLabel.superview?.addGestureRecognizer(viewsTap)
        
        let commentsTap = UITapGestureRecognizer(target: self, action: #selector(commentsTapped))
        commentsLabel.superview?.isUserInteractionEnabled = true
        commentsLabel.superview?.addGestureRecognizer(commentsTap)
    }
    
    func setupNotificationsButton(_ _subscribed:Bool) {
        subscribed = _subscribed
        if subscribed! {
            self.subscribeButton.setImage(UIImage(named:"notifications"), for: .normal)
        } else {
            self.subscribeButton.setImage(UIImage(named:"notifications_muted"), for: .normal)
        }
        subscribeButton.isEnabled = true
    }
    @IBAction func subscribeTapped(_ sender: Any) {
        if subscribed == nil || postKey == nil { return }
        
        UploadService.subscribeToPost(withKey: postKey!, subscribe: !subscribed!)
    }
    
    func viewsTapped() {
        delegate?.setInfoMode(.Viewers)
        self.viewsLabel.superview!.alpha = 0.5
        UIView.animate(withDuration: 0.2, animations: {
            self.viewsLabel.superview!.alpha = 1.0
        }, completion: { _ in
            
        })
    }
    
    func commentsTapped() {
        delegate?.setInfoMode(.Comments)
        self.commentsLabel.superview!.alpha = 0.5

        UIView.animate(withDuration: 0.25, animations: {
            self.commentsLabel.superview!.alpha = 1.0
        }, completion: { _ in
            
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

    
    @IBAction func handleMore(_ sender: Any) {
        delegate?.actionHandler()
    }
    
    func setUserInfo(uid:String) {
       
        
        if uid == mainStore.state.userState.uid {
            rightButton.setImage(UIImage(named:"trash_2"), for: .normal)
            //rightButton.imageEdgeInsets = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
        } else {
            rightButton.setImage(UIImage(named:"report"), for: .normal)
            //rightButton.imageEdgeInsets = UIEdgeInsets(top: 14.0, left: 14.0, bottom: 14.0, right: 14.0)
        }
    }
    
    func setViewsLabel(count:Int) {
        self.viewsLabel.text = getNumericShorthandString(count)
    }
    
    
    func setCommentsLabel(count:Int) {
        
        self.commentsLabel.text = getNumericShorthandString(count)
    }
    
    
}
