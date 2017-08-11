//
//  CameraButton.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class CameraButton: UIView {
    
    var tap:UITapGestureRecognizer!
    var press:UILongPressGestureRecognizer!
    var ring:UIButton!
    
    var progresser:KDCircularProgress!
    
    var redCircle:UIView!
    var interactionView:UIView!
    
    var tappedHandler:(()->())?
    var pressedHandler:((_ state:UIGestureRecognizerState)->())?
    
    
    override init(frame:CGRect) {
        super.init(frame:frame)

        
        ring = UIButton(frame: frame)
        ring.backgroundColor = UIColor.clear
        ring.layer.cornerRadius = ring.frame.height/2
        ring.layer.borderColor = UIColor.white.cgColor
        ring.layer.borderWidth = 7
        ring.clipsToBounds = true
        ring.layer.masksToBounds = true
        ring.tintColor = UIColor.white
        ring.isUserInteractionEnabled = true
        ring.center = CGPoint(x: self.frame.width / 2,y: self.frame.height/2)
        //ring.applyShadow(1, opacity: 0.25, height: 1, shouldRasterize: false)
        self.isUserInteractionEnabled = true
        
        let pMargin:CGFloat = 12.0
        let pFrame = CGRect(x: ring.frame.origin.x - pMargin, y: ring.frame.origin.y - pMargin, width: ring.frame.width + pMargin * 2, height: ring.frame.height + pMargin * 2)
        progresser = KDCircularProgress(frame: pFrame)
        progresser.startAngle = -90
        progresser.progressThickness = 0.25
        progresser.trackThickness = 0.25
        progresser.trackColor = UIColor.clear
        progresser.clockwise = true
        progresser.glowAmount = 0.0
        progresser.gradientRotateSpeed = 1
        
        progresser.roundedCorners = true
        
        progresser.angle = 0

        progresser.progressColors = [UIColor.white]
        progresser.layer.addSublayer(ring.layer)
        progresser.layer.mask = ring.layer
        progresser.layer.masksToBounds = true
        
        redCircle = UIView(frame: frame)
        redCircle.layer.cornerRadius = redCircle.frame.width/2
        redCircle.clipsToBounds = true
        redCircle.backgroundColor = UIColor.white
        
        //UIColor(colorLiteralRed: 205/255, green: 0, blue: 0, alpha: 1.0)
        redCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        interactionView = UIView(frame: frame)
        interactionView.layer.cornerRadius = interactionView.frame.width/2
        interactionView.clipsToBounds = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        interactionView.addGestureRecognizer(tap)
        
        press = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
        press.minimumPressDuration = 0.3
        interactionView.addGestureRecognizer(press)
        interactionView.isUserInteractionEnabled = true
        addSubview(redCircle)
        addSubview(ring)
        addSubview(progresser)
        addSubview(interactionView)
        
        self.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        
    }
    
    func tapped(sender:UITapGestureRecognizer) {
        
        tappedHandler?()
        if !UserService.isEmailVerified {
            return
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.ring.alpha = 0.4
        }
            , completion: { result in
                self.ring.alpha = 1.0
        })
    }
    
    func pressed(sender: UILongPressGestureRecognizer)
    {
        
        let state = sender.state
        pressedHandler?(state)
        if !UserService.isEmailVerified {
            return
        }
        switch state {
        case .began:
            UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
                self.ring.alpha = 0.333
                //self.ring.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
                self.redCircle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.transform = CGAffineTransform.identity
            }, completion: { result in })
            break
        case .ended:
            break
        default:
            break
        }
        
        // animate
    }
    
    func addGestures() {
        interactionView.addGestureRecognizer(press)
    }
    
    func removeGestures() {
        interactionView.removeGestureRecognizer(press)
    }
    
    func updateProgress(progress:CGFloat) {
        let t = progress
        var amount:CGFloat!
        if t < 0.5 {
            amount = 2*t*t
        } else {
            amount = -1+(4-2*t)*t
        }
        progresser.angle = 360.0 * Double(amount)
       
        progresser.set(colors: lightAccentColor, lightAccentColor, darkAccentColor, darkAccentColor)
    }
    
    func resetProgress() {
        progresser.angle = 0
        UIView.animate(withDuration: 0.05, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.ring.alpha = 1.0
            self.redCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
            self.ring.transform = CGAffineTransform.identity
            self.transform = CGAffineTransform(scaleX: 0.70, y: 0.70)
        }, completion: { result in })
        
    }
    
    
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    
}
