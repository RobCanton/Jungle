//
//  CommentsHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class CommentsHeaderView: UIView {

    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    var closeHandler:(()->())?
    var moreHandler:(()->())?

    @IBAction func handleClose(_ sender: Any) {
        closeHandler?()
    }
    
    @IBAction func handleMore(_ sender: Any) {
        moreHandler?()
    }
    
    func setUserInfo(uid:String) {
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.clipsToBounds = true
        
        if uid == mainStore.state.userState.uid {
            rightButton.setImage(UIImage(named:"trash"), for: .normal)
        } else {
            rightButton.setImage(UIImage(named:"more"), for: .normal)
        }
        
        
        UserService.getUser(uid, completion: { user in
            if user != nil {
                self.imageView.loadImageAsync(user!.getImageUrl(), completion: { result in })
                let username = "\(user!.getUsername())'s"
                let str = "\(username) post"
                let attributes: [String: AnyObject] = [
                    NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
                ]
                
                let title = NSMutableAttributedString(string: str, attributes: attributes) //1
                
                if let range = str.range(of: username) {// .rangeOfString(countStr) {
                    let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
                    let a: [String: AnyObject] = [
                        NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold),
                    ]
                    title.addAttributes(a, range: NSRange(location: index, length: username.characters.count))
                }
                
                self.usernameLabel.attributedText = title
                
            }
        })
    }
}
