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
            if cachedNotification.getType() != .comment || cachedNotification.getType() != .comment_also || cachedNotification.getType() != .comment_to_sub  {
               return completion(cachedNotification, true)
            }
        }
        
        let ref = FIRDatabase.database().reference()
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
                let numCommenters   = dict["commenters"] as? Int
                notification = Notification(key: key, type: type, date: date, sender: sender, postKey: postKey, text: text, numCommenters: numCommenters)
                dataCache.setObject(notification!, forKey: "notification-\(key)" as NSString)
            }
            return completion(notification, false)
        }, withCancel: { error in
            return completion(nil, false)
        })
        
        
    }
    
    static func markNotificationAsSeen(key:String) {
        let uid = mainStore.state.userState.uid
        let ref = FIRDatabase.database().reference()
        let notificationRef = ref.child("users/notifications/\(uid)/\(key)")
        notificationRef.setValue(true)
    }
}
