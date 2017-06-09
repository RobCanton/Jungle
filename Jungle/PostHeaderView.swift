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
    func showPlace(_ location:Location)
    func dismiss()
    func showComments()
}

class PostHeaderView: UIView {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var snapTimer: SnapTimerView!
    
    @IBOutlet weak var likesView: UIView!
    @IBOutlet weak var commentsView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var locationIcon: UIButton!
    
    
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    var commentsTap:UITapGestureRecognizer?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImageView.cropToCircle()
        
    }
    
    @IBAction func handleClose(_ sender: Any) {
            delegate?.dismiss()
    }
    
    weak var delegate:PostHeaderProtocol?
    var tap:UITapGestureRecognizer?
    var tap2:UITapGestureRecognizer?
    
    var placeTap:UITapGestureRecognizer?
    var placeTap2:UITapGestureRecognizer?
    func setup(withUid uid:String, date: Date?,  _delegate:PostHeaderProtocol?) {
        delegate = _delegate
        
        clean()
        UserService.getUser(uid, completion: { _user in
            guard let user = _user else { return }
            self.userImageView.loadImageAsync(user.imageURL, completion: { _ in })
            self.usernameLabel.text = user.username
            if date != nil {
                self.timeLabel.text = date!.timeStringSinceNow()
                self.timeLabel2.text = self.timeLabel.text
            }
            
        })
        
        tap = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(tap!)
        tap2 = UITapGestureRecognizer(target: self, action: #selector(self.userTapped))
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tap2!)
        commentsTap = UITapGestureRecognizer(target: self, action: #selector(self.commentsTapped))
        self.commentsView.isUserInteractionEnabled = true
        self.commentsView.addGestureRecognizer(commentsTap!)
        
        //self.applyShadow(radius: 3.0, opacity: 0.5, height: 0.0, shouldRasterize: false)
        likesView.layer.cornerRadius = 3.0
        likesView.clipsToBounds = true
        
        commentsView.layer.cornerRadius = 3.0
        commentsView.clipsToBounds = true
    }
    
    func setNumLikes(_ numLikes:Int) {
        likesLabel.text = getNumericShorthandString(numLikes)
    }
    
    func setNumComments(_ numComments:Int) {
        commentsLabel.text = getNumericShorthandString(numComments)
    }
    
    @IBOutlet weak var timeLabel2: UILabel!
    
    func commentsTapped() {
        delegate?.showComments()
    }
    
    func clean() {
        self.userImageView.image = nil
        self.usernameLabel.text = ""
        self.timeLabel.text = ""
        self.timeLabel2.text = ""
        if tap != nil {
            self.userImageView.removeGestureRecognizer(tap!)
        }
        if tap2 != nil {
            self.usernameLabel.removeGestureRecognizer(tap2!)
        }
        locationTitle.text = ""
        locationIcon.isHidden = true
        
    }
    
    func userTapped(tap:UITapGestureRecognizer) {
        delegate?.showAuthor()
    }
    
    weak var location:Location?
    
    func setupLocation(locationKey:String?) {
        
        if locationKey != nil {
            timeLabel2.isHidden = true
            timeLabel.isHidden = false
            locationTitle.text = "Loading..."
            LocationService.sharedInstance.getLocationInfo(locationKey!) { location in
                self.locationRetrieved(location)
            }
        } else {
            timeLabel2.isHidden = false
            timeLabel.isHidden = true
            clearLocation()
        }
        
    }
    
    func locationRetrieved(_ location:Location?) {
        self.location = location
        if location != nil {
            locationTitle.text = location!.name
            locationIcon.isHidden = false
            placeTap = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
            self.locationTitle.isUserInteractionEnabled = true
            self.locationTitle.addGestureRecognizer(placeTap!)
            placeTap2 = UITapGestureRecognizer(target: self, action: #selector(self.locationTapped))
            self.locationIcon.isUserInteractionEnabled = true
            self.locationIcon.addGestureRecognizer(placeTap2!)
        } else {
            clearLocation()
        }
    }
    
    func clearLocation() {
        locationTitle.text = ""
        locationIcon.isHidden = true
        if placeTap != nil {
            self.locationTitle.removeGestureRecognizer(placeTap!)
            placeTap = nil
        }
        if placeTap2 != nil {
            self.locationIcon.removeGestureRecognizer(placeTap2!)
            placeTap2 = nil
        }
    }
    
    func locationTapped(tap:UITapGestureRecognizer) {
        guard let loc = self.location else { return }
        print("PRESENT LOCATION: \(loc.name)")
        delegate?.showPlace(loc)
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
