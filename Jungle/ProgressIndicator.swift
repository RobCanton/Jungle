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
        paused = false
        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.duration = duration
        animation.fromValue = progress.bounds.width
        animation.toValue = bounds.width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        progress.layer.speed = 1.0
        progress.layer.anchorPoint = CGPoint(x: 0,y: 0.5)
        progress.layer.add(animation, forKey: "bounds")
    }
    
    func pauseAnimation() {
        if !paused {
            paused = true
            print("layer paused: \(paused)")
            let layer = progress.layer
            let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
            layer.speed = 0.0
            layer.timeOffset = pausedTime
        }
    }
    
    func resumeAnimation() {
        if !paused { return }
        
        paused = false
        print("layer paused: \(paused)")
        
        let layer = progress.layer
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
        print("layer beginTime \(layer.beginTime)")
    }
    
    func removeAnimation() {
        print("layer removeAnimation")
        progress.layer.removeAnimation(forKey: "bounds")
    }
    
    func completeAnimation() {
        
        removeAnimation()
        completeProgress()
        print("layer completeAnimation")
    }
    
    func completeProgress() {
        progress.frame = CGRect(x: 0,y: 0,width: bounds.width,height: bounds.height)
    }
    
    func resetProgress() {
        paused = false
        print("layer resetProgress")
        progress.layer.speed = 1.0
        progress.layer.timeOffset = 0.0
        progress.layer.beginTime = 0.0
        progress.frame = CGRect(x: 0,y: 0,width: 0,height: bounds.height)
    }

}
