//
//  StoryProgressIndicator.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-12.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit



class StoryProgressIndicator: UIView {
    
    var progressBars = [ProgressIndicator]()
    var totalLength: Double = 0
    var currentProgress: Double = 0
    var x: CGFloat = 0
    
    let gap: CGFloat = 2.0
    
    var storyItems:[StoryItem]!
    
    var activeBarIndex = 0

    func createProgressIndicator(_story:Story) {
        //destroyStoryProgressIndicator()
        progressBars = [ProgressIndicator]()
        storyItems = _story.items!
        if storyItems.count > 0 {
            
            let totalWidth = self.frame.width
            let gapWidth = CGFloat(storyItems.count - 1) * gap
            
            
            let widthMinusGap = totalWidth - gapWidth
            let itemWidth = widthMinusGap / CGFloat(storyItems.count)
            
            for item in storyItems {
                totalLength += item.length
            }
            
            for i in 0 ... storyItems.count - 1 {
                let barWidth = itemWidth
                let frame = CGRect(x: x, y: CGFloat(0), width: barWidth, height: 2.0)
                let bar = ProgressIndicator(frame: frame)
                progressBars.append(bar)
                self.addSubview(bar)
                
                x += barWidth + gap
           
            }
        }
    }

    func hideAll(_ hide:Bool) {
        for bar in progressBars {
            bar.isHidden = hide
        }
    }
    
    func activateIndicator(itemIndex:Int) {
        if itemIndex >= 0 && itemIndex < storyItems.count {
            activeBarIndex = itemIndex
            
            if activeBarIndex > 0 {
                for i in 0..<activeBarIndex {
                    progressBars[i].completeAnimation()
                }
                
            }
            for j in activeBarIndex..<progressBars.count {
                progressBars[j].removeAnimation()
                progressBars[j].resetProgress()
            }
            
            let bar = progressBars[activeBarIndex]
            let item = storyItems[activeBarIndex]
            bar.startAnimating(duration: item.length)
        }
    }
    
    func resetActiveIndicator() {
        getActiveIndicator()?.removeAnimation()
        getActiveIndicator()?.resetProgress()
    }
    
    func pauseActiveIndicator() {
        getActiveIndicator()?.pauseAnimation()
    }
    
    func resumeActiveIndicator() {
        getActiveIndicator()?.resumeAnimation()
    }
    
    private func getActiveIndicator() -> ProgressIndicator? {
        if activeBarIndex >= 0 && activeBarIndex < progressBars.count {
            return progressBars[activeBarIndex]
        }
        return nil
    }
    
    
    func resetAllProgressBars() {
        for bar in progressBars {
            bar.removeAnimation()
            bar.resetProgress()
        }
    }
    
    func destroyStoryProgressIndicator() {
        for bar in progressBars {
            bar.removeAnimation()
            bar.resetProgress()
            bar.removeFromSuperview()
        }
        progressBars = [ProgressIndicator]()
    }
    

//

    
}

