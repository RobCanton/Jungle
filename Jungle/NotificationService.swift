//
//  NotificationService.swift
//  Jungle
//
//  Created by Robert Canton on 2017-04-05.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import ReSwift
import UserNotifications

protocol NotificationServiceProtocol:ServiceProtocol {
    func notificationsUpdated(_ notificationsDict:[String:Bool])
}


class NotificationService: Service, UNUserNotificationCenterDelegate {
    
    private(set) var notifications:[String:Bool]!
    private(set) var cache:NSCache<NSString, AnyObject>!
    
    override init(_ subscribers:[String:ServiceProtocol]) {
        super.init(subscribers)
        cache = NSCache<NSString, AnyObject>()
        notifications = [String:Bool]()
       
    }
    
    internal override func subscribe(_ name: String, subscriber: ServiceProtocol) {
        if let s = subscriber as? NotificationServiceProtocol {
            super.subscribe(name, subscriber: s)
            s.notificationsUpdated(self.notifications)
        }
    }
    
    fileprivate func getSubscribers() -> [String:NotificationServiceProtocol]? {
        guard let subscribers = subscribers as? [String:NotificationServiceProtocol] else { return nil }
        return subscribers
    }
    
    fileprivate func updateSubscribers() {
        guard let subscribers = getSubscribers() else { return }
        subscribers.forEach { $0.value.notificationsUpdated(notifications) }
    }
    
    internal func clear() {
        cache = NSCache<NSString, AnyObject>()
        notifications = [String:Bool]()
        clearSubscribers()
    }
    
    internal func startListeningToNotifications() {
        let current_uid = mainStore.state.userState.uid
        let ref = Database.database().reference()
        let notificationsRef = ref.child("users/notifications/\(current_uid)")
        notificationsRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: 50).observe(.childAdded, with: { snapshot in
            if snapshot.exists() {
                guard let dict = snapshot.value as? [String:Any] else { return }
                self.notifications[snapshot.key] = dict["seen"] as! Bool
                self.updateSubscribers()
            }
        })
        
        notificationsRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: 50).observe(.childChanged, with: { snapshot in
            if snapshot.exists() {
                guard let dict = snapshot.value as? [String:Any] else { return }
                self.notifications[snapshot.key] = dict["seen"] as! Bool
                self.updateSubscribers()
            }
        })
        
        notificationsRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: 50).observe(.childRemoved, with: { snapshot in
            self.notifications[snapshot.key] = nil
            self.cache.removeObject(forKey: "notification-\(snapshot.key)" as NSString)
            self.updateSubscribers()
        })
    }
    
    
    internal func stopListeningToNotifications() {
        let uid = mainStore.state.userState.uid
        let ref = Database.database().reference()
        let notificationsRef = ref.child("notifications/\(uid)")
        notificationsRef.removeAllObservers()
    }
    
    internal func getNotification(_ key:String, completion: @escaping((_ notification:Notification?, _ fromCache: Bool)->())) {
        
        if let cachedNotification = cache.object(forKey: "notification-\(key)" as NSString) as? Notification {
            if cachedNotification.type != .comment || cachedNotification.type != .comment_also || cachedNotification.type != .comment_to_sub  {
                return completion(cachedNotification, true)
            }
        }
        
        let ref = Database.database().reference()
        let notificationsRef = ref.child("notifications/\(key)")
        notificationsRef.observeSingleEvent(of: .value, with: { snapshot in
            var notification:Notification?
            if snapshot.exists() {
                let key             = snapshot.key
                guard let dict      = snapshot.value as? [String:AnyObject] else { return completion(notification, false)}
                guard let sender    = dict["sender"] as? String else { return completion(notification, false)}
                guard let timestamp = dict["timestamp"] as? Double else { return completion(notification, false)}
                guard let type      = dict["type"] as? String else { return completion(notification, false)}
                let postKey         = dict["postKey"] as? String
                let date            = Date(timeIntervalSince1970: timestamp/1000)
                let text            = dict["text"] as? String
                let count           = dict["count"] as? Int
                
                if let anon = dict["anon"] as? [String:Any] {
                    let adjective = anon["adjective"] as! String
                    let animal = anon["animal"] as! String
                    let colorHexcode = anon["color"] as! String
                    notification = AnonymousNotification(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count, adjective: adjective, animal: animal, colorHexcode: colorHexcode)
                } else {
                    notification = Notification(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count)
                }
                self.cache.setObject(notification!, forKey: "notification-\(key)" as NSString)
            } else {
                print("Notification doesn't exist")
            }
            return completion(notification, false)
        }, withCancel: { error in
            print("Notification canceled")
            return completion(nil, false)
        })
        
        
    }
    
    internal func markNotificationAsSeen(key:String) {
        let uid = mainStore.state.userState.uid
        let ref = Database.database().reference()
        let notificationRef = ref.child("users/notifications/\(uid)/\(key)/seen")
        notificationRef.setValue(true)
    }
    
    internal func markAllNotificationsAsSeen() {
        for (key,seen) in notifications {
            if !seen {
                markNotificationAsSeen(key: key)
            }
        }
    }
    
    
    func registerForNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]){
                (granted,error) in
                if granted{
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("User Notification permission denied: \(String(describing: error?.localizedDescription))")
                }
                
            }
        } else {
            // Fallback on earlier versions
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    

}
