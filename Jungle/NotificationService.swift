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


protocol NotificationServiceProtocol:ServiceProtocol {
    func notificationsUpdated(_ notificationsDict:[String:Bool])
}


class NotificationService: Service {
    
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
        notificationsRef.observe(.childAdded, with: { snapshot in
            if snapshot.exists() {
                guard let seen = snapshot.value as? Bool else { return }
                self.notifications[snapshot.key] = seen
                self.updateSubscribers()
            }
        })
        
        notificationsRef.observe(.childChanged, with: { snapshot in
            if snapshot.exists() {
                guard let seen = snapshot.value as? Bool else { return }
                self.notifications[snapshot.key] = seen
                self.updateSubscribers()
            }
        })
        
        notificationsRef.observe(.childRemoved, with: { snapshot in
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
                notification = Notification(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, count: count)
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
        let notificationRef = ref.child("users/notifications/\(uid)/\(key)")
        notificationRef.setValue(true)
    }
    
    internal func markAllNotificationsAsSeen() {
        for (key,seen) in notifications {
            if !seen {
                markNotificationAsSeen(key: key)
            }
        }
    }

}
