//
//  MainTabBarController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-19.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import ReSwift

class MainTabBarController: UITabBarController, StoreSubscriber, MessageServiceProtocol, NotificationServiceProtocol{
    
    let identifier = "MainTabBarController"
    weak var message_service:MessageService?
    weak var notification_service:NotificationService?
    
    
    var unseenMessages = 0
    var unseenNotifications = 0
    
    var notificationDots = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false
        self.edgesForExtendedLayout = []
        
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5))
        bar.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        tabBar.addSubview(bar)
        
        let tabBarItem1 = tabBar.items![0] as UITabBarItem
        let tabBarItem2 = tabBar.items![1] as UITabBarItem
        let tabBarItem4 = tabBar.items![3] as UITabBarItem
        let tabBarItem5 = tabBar.items![4] as UITabBarItem
        
        tabBarItem1.selectedImage = UIImage(named: "home_filled")
        tabBarItem2.selectedImage = UIImage(named: "message_filled")
        tabBarItem4.selectedImage = UIImage(named: "notifications_filled")
        tabBarItem5.selectedImage = UIImage(named: "profile_filled")

        let halfGap = view.frame.width / 10
        let yPos = view.frame.height - 27.5
        
        let dot1 = makeDot()
        let dot2 = makeDot()
        let dot3 = makeDot()
        let dot4 = makeDot()
        
        notificationDots.append(dot1)
        notificationDots.append(dot2)
        notificationDots.append(dot3)
        notificationDots.append(dot4)
        
        
        dot1.center = CGPoint(x: halfGap, y: yPos)
        dot2.center = CGPoint(x: halfGap * 3, y: yPos)
        dot3.center = CGPoint(x: halfGap * 7, y: yPos)
        dot4.center = CGPoint(x: halfGap * 9, y: yPos)
        
        
        for dot in notificationDots {
            dot.isHidden = true
            view.addSubview(dot)
        }
        
    }
    
    func makeDot() -> UIView {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
        dot.backgroundColor = infoColor
        dot.layer.cornerRadius = dot.frame.width / 2
        dot.clipsToBounds = true
        return dot
    }
    
    func newState(state:AppState) {
        
        tabBar.items?[4].badgeValue = UserService.isEmailVerified ? nil : "\(1)"
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        message_service?.subscribe(identifier, subscriber: self)
        notification_service?.subscribe(identifier, subscriber: self)
        
        tabBar.items?[4].badgeValue = UserService.isEmailVerified ? nil : "\(1)"
        //notificationDots[3].isHidden = UserService.isEmailVerified ? true : false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        message_service?.unsubscribe(identifier)
        notification_service?.unsubscribe(identifier)
    }
    
    func conversationsUpdated(_ conversations: [Conversation]) {
        var _unseenMessages = 0
        for conversation in conversations {
            if !conversation.getSeen() {
                _unseenMessages += 1
            }
        }
        
        unseenMessages = _unseenMessages
        
        tabBar.items?[1].badgeValue = unseenMessages > 0 ? "\(unseenMessages)" : nil
        //notificationDots[1].isHidden = unseenMessages == 0 ? true : false
        
        UIApplication.shared.applicationIconBadgeNumber = unseenMessages + unseenNotifications
    }
    
    func notificationsUpdated(_ notificationsDict: [String : Bool]) {
        var _unseenNotifications = 0
        for (_, seen) in notificationsDict {
            if !seen {
                _unseenNotifications += 1
            }
        }
        
        unseenNotifications = _unseenNotifications
        tabBar.items?[3].badgeValue = unseenNotifications > 0 ? "\(unseenNotifications)" : nil
        //notificationDots[2].isHidden = unseenNotifications == 0 ? true : false
        
        UIApplication.shared.applicationIconBadgeNumber = unseenMessages + unseenNotifications
        
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
        
        backDrop.layer.cornerRadius = 24.0
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
