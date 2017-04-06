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


class NotificationService {
    
    static func getNotification(_ key:String, completion: @escaping((_ notification:Notification?, _ fromCache: Bool)->())) {
        
        if let cachedNotification = dataCache.object(forKey: "notification-\(key)" as NSString) as? Notification {
            return completion(cachedNotification, true)
        }
        
        let ref = FIRDatabase.database().reference()
        let notificationsRef = ref.child("notifications/\(key)")
        notificationsRef.observe(.value, with: { snapshot in
            var notification:Notification?
            if snapshot.exists() {
                let key             = snapshot.key
                guard let dict      = snapshot.value as? [String:AnyObject] else { return completion(notification, false)}
                guard let sender    = dict["sender"] as? String else { return completion(notification, false)}
                guard let timestamp = dict["timestamp"] as? Double else { return completion(notification, false)}
                guard let type      = dict["type"] as? String else { return completion(notification, false)}
                let postKey         = dict["postKey"] as? String
                let date            = Date(timeIntervalSince1970: timestamp/1000)
                notification = Notification(key: key, type: type, date: date, sender: sender, postKey: postKey)
                dataCache.setObject(notification!, forKey: "notification-\(key)" as NSString)
            }
            return completion(notification, false)
        })
    }
    
    static func markNotificationAsSeen(key:String) {
        let uid = mainStore.state.userState.uid
        let ref = FIRDatabase.database().reference()
        let notificationRef = ref.child("users/notifications/\(uid)/\(key)")
        notificationRef.setValue(true)
    }
}
