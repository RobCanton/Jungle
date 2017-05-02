//
//  PostAuthorView.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-15.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import SnapTimer

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
    
    var location:Location!
    var showAuthorHandler:(()->())?
    
    
    func setup(withUser user:User, date: Date?, optionsHandler:(()->())?) {
        
        self.userImageView.image = nil
        self.userImageView.loadImageAsync(user.getImageUrl(), completion: { _ in })
        self.usernameLabel.text = user.getUsername()
        if date != nil {
            self.timeLabel.text = date!.timeStringSinceNow()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tap2)
        
    }
    
    func userTapped(tap:UITapGestureRecognizer) {
        showAuthorHandler?()
    }
    
    func setupLocation(location:Location) {
        locationTitle.text = location.getName()
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
