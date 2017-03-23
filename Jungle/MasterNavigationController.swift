//
//  MasterNavigationController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class MasterNavigationController: UINavigationController {
    
    
    
}


class MyNavigationBar: UINavigationBar {
    private var secondTap = false
    private var firstTapPoint = CGPoint.zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !self.secondTap{
            self.firstTapPoint = point
        }
        
        defer{
            self.secondTap = !self.secondTap
        }
        
        return  super.point(inside: firstTapPoint, with: event)
    }
}

/*extension UINavigationBar {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.isTranslucent {
            let v = super.hitTest(point, with: event)
            return v
        } else {
            return nil
        }
    }
}*/
