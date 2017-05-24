//
//  MainTabBarController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController, MessageServiceProtocol, NotificationServiceProtocol{
    
    let identifier = "MainTabBarController"
    weak var message_service:MessageService?
    weak var notification_service:NotificationService?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false
        self.edgesForExtendedLayout = []
        
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        
        let tabBarItem1 = tabBar.items![0] as UITabBarItem
        let tabBarItem2 = tabBar.items![1] as UITabBarItem
        let tabBarItem4 = tabBar.items![3] as UITabBarItem
        let tabBarItem5 = tabBar.items![4] as UITabBarItem
        
        tabBarItem1.selectedImage = UIImage(named: "home_filled")
        tabBarItem2.selectedImage = UIImage(named: "message_filled")
        tabBarItem4.selectedImage = UIImage(named: "notifications_filled")
        tabBarItem5.selectedImage = UIImage(named: "user_filled")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        message_service?.subscribe(identifier, subscriber: self)
        notification_service?.subscribe(identifier, subscriber: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        message_service?.unsubscribe(identifier)
        notification_service?.unsubscribe(identifier)
    }
    
    func conversationsUpdated(_ conversations: [Conversation]) {
        var unseenMessages = 0
        for conversation in conversations {
            if !conversation.getSeen() {
                unseenMessages += 1
            }
        }
        
        tabBar.items?[1].badgeValue = unseenMessages > 0 ? "\(unseenMessages)" : nil
    }
    
    func notificationsUpdated(_ notificationsDict: [String : Bool]) {
        var unseenNotifications = 0
        for (_, seen) in notificationsDict {
            if !seen {
                unseenNotifications += 1
            }
        }
        
        tabBar.items?[3].badgeValue = unseenNotifications > 0 ? "\(unseenNotifications)" : nil
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
