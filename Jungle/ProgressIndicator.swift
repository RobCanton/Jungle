//
//  ProgressIndicator.swift
//  Lit
//
//  Created by Robert Canton on 2016-12-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class ProgressIndicator: UIView {

    var progress:UIView!
    var paused = false
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        
        self.layer.cornerRadius = frame.height / 2
        self.clipsToBounds = true
        
        
        backgroundColor = UIColor(white: 1.0, alpha: 0.10)
        
        progress = UIView()
        resetProgress()
        progress.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        addSubview(progress)
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func startAnimating(duration:Double) {
        removeAnimation()
        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.duration = duration
        animation.fromValue = progress.bounds.width
        animation.toValue = bounds.width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        progress.layer.anchorPoint = CGPoint(x: 0,y: 0.5)
        progress.layer.add(animation, forKey: "bounds")
    }
    
    func pauseAnimation() {
        if !paused {
            paused = true
            let pausedTime = progress.layer.convertTime(CACurrentMediaTime(), to: nil)
            progress.layer.speed = 0.0
            progress.layer.timeOffset = pausedTime
        }
    }
    
    func removeAnimation() {
        progress.layer.removeAnimation(forKey: "bounds")
    }
    
    func completeAnimation() {
        removeAnimation()
        completeProgress()
    }
    
    func completeProgress() {
        progress.frame = CGRect(x: 0,y: 0,width: bounds.width,height: bounds.height)
    }
    
    func resetProgress() {
        progress.frame = CGRect(x: 0,y: 0,width: 0,height: bounds.height)
    }

}
