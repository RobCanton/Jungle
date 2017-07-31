//
//  PostSendOptionsBar.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-28.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

protocol SendOptionsBarProtocol: class {
    
    func sendPost()
    
}

class PostSendOptionsBar: UIView {
    
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var send: UIButton!
    
    weak var delegate:SendOptionsBarProtocol?

    @IBOutlet weak var SendButtonWidth: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        send.layer.cornerRadius = send.frame.height / 2
        send.clipsToBounds = true
        
        
        userImage.layer.cornerRadius = userImage.frame.height / 2
        userImage.clipsToBounds = true
        
        userImage.layer.borderWidth = 2
        userImage.layer.borderColor = UIColor.clear.cgColor
    }

    func setup() {
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(switchAnonMode))
        userImage.isUserInteractionEnabled = true
        userImage.addGestureRecognizer(tap2)
        
        showCurrentAnonMode()
    }
    
    @IBAction func sendPost(_ sender: Any) {
        delegate?.sendPost()
    }
    
    func switchAnonMode() {
        mainStore.dispatch(ToggleAnonMode())
        showCurrentAnonMode()
        
    }
    
    func showCurrentAnonMode() {
        let isAnon = mainStore.state.userState.anonMode
        if isAnon {
            
            userImage.image = UIImage(named:"private2")
            send.backgroundColor = accentColor
            userImage.layer.borderColor = accentColor.cgColor
            userImage.backgroundColor = accentColor
            setButtonTitle("Post anonymously")
            
        } else {
            guard let user = mainStore.state.userState.user else {
                return
            }
            userImage.image = nil
            userImage.loadImageAsync(user.imageURL, completion: nil)
            send.backgroundColor = infoColor
            userImage.layer.borderColor = infoColor.cgColor
            userImage.backgroundColor = infoColor
            setButtonTitle("Post as @\(user.username)")

        }
    }
    
    func setButtonTitle(_ text:String) {
        let size = UILabel.size(withText: text, forHeight: send.frame.height, withFont: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightBold))
        SendButtonWidth.constant = size.width + 32
        send.setTitle(text, for: .normal)
        
    }
    
}
