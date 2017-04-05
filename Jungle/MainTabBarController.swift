//
//  MainTabBarController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import ReSwift
class MainTabBarController: UITabBarController, StoreSubscriber{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false
        self.edgesForExtendedLayout = []
        
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        
        var unseenNotifications = 0
        for (_, seen) in state.notifications {
            if !seen {
                unseenNotifications += 1
            }
        }
        
        if unseenNotifications > 0 {
            tabBar.items?[3].badgeValue = "\(unseenNotifications)"
        } else {
            tabBar.items?[3].badgeValue = nil
        }
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let _ = viewController as? DummyViewController {
            return false
        }
        return true
    }
    
}


class RoundedViewController:UIViewController {
    
    var backDrop:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = []
        
        self.view.backgroundColor = UIColor.clear
        backDrop = UIView(frame: self.view.bounds)
        backDrop.backgroundColor = UIColor.white
        
        backDrop.layer.cornerRadius = 16.0
        backDrop.clipsToBounds = true
        
        self.view.addSubview(backDrop)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

class DummyViewController: UIViewController {
    
}
