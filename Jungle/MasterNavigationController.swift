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
    
    func activateNavbar(_ activate: Bool) {
        let navbar = navigationBar as! MasterNavigationBar
        navbar.ignoreTouches = !activate
    }
}


class MasterNavigationBar: UINavigationBar {
    var ignoreTouches = false
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !ignoreTouches {
            let v = super.hitTest(point, with: event)
            return v
        } else {
            return nil
        }
    }
}

//extension UINavigationBar {
//    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        if !self.isTranslucent {
//            let v = super.hitTest(point, with: event)
//            return v
//        } else {
//            return nil
//        }
//    }
//}
