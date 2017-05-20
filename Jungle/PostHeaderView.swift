//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import SnapTimer

protocol PostHeaderProtocol: class {
    func showAuthor()
}

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var snapTimer: SnapTimerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImageView.cropToCircle()
        
    }
    
    weak var delegate:PostHeaderProtocol?
    
    func setup(withUid uid:String, date: Date?, _delegate:PostHeaderProtocol?) {
        delegate = _delegate
        
        UserService.getUser(uid, completion: { _user in
            guard let user = _user else { return }
        
            self.userImageView.image = nil
            self.userImageView.loadImageAsync(user.getImageUrl(), completion: { _ in })
            self.usernameLabel.text = user.getUsername()
            if date != nil {
                self.timeLabel.text = date!.timeStringSinceNow()
            }
            
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tap2)
        
        
    }
    
    func userTapped(tap:UITapGestureRecognizer) {
        delegate?.showAuthor()
    }
    
    func setupLocation(location:Location?) {
        if location != nil {
            locationTitle.text = location!.getName()
        } else {
            locationTitle.text = ""
        }
    }
    
    
    func startTimer(length:Double, index:Int, total:Int) {
        let timeInterval = TimeInterval(length)

        let innerStart = (CGFloat(index) / CGFloat(total)) * 100.0
        
        DispatchQueue.main.async {
            
            self.snapTimer.animateInnerToValue(innerStart, duration: 0.0, completion: { _ in
                self.snapTimer.animateOuterToValue(0.0, duration: 0.0, completion: { _ in
                    self.snapTimer.animateInnerToValue((CGFloat(index + 1) / CGFloat(total)) * 100.0, duration: timeInterval, completion: nil)
                    self.snapTimer.animateOuterToValue(100, duration:timeInterval, completion: nil)
                })
            })

        }
    }
    
    func pauseTimer() {
        self.snapTimer.pauseAnimation()
    }
    
    func resumeTimer() {
        self.snapTimer.resumeAnimation()
    }
    
    
}
