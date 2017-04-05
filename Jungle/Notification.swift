//
//  Notification.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//


import Foundation

enum NotificationType:String {
    case comment = "COMMENT"
    case follow  = "FOLLOW"
    case none  = "NONE"
}

class Notification: NSObject {
    
    fileprivate var key:String                    // Key in database
    fileprivate var type:NotificationType
    fileprivate var date:Date
    fileprivate var sender:String
    fileprivate var postKey:String?
    
    init(key:String, type:String, date:Date, sender:String, postKey:String?)
    {
        self.key          = key
        switch type {
        case NotificationType.comment.rawValue:
            self.type = .comment
            break
        case NotificationType.follow.rawValue:
            self.type = .follow
            break
        default:
            self.type = .none
            break
        }
        
        self.date = date
        self.sender = sender
        self.postKey = postKey
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let type = decoder.decodeObject(forKey: "type") as! String
        let date = decoder.decodeObject(forKey: "date") as! Date
        let sender = decoder.decodeObject(forKey: "sender") as! String
        let postKey = decoder.decodeObject(forKey: "postKey") as? String
        self.init(key: key, type: type, date: date, sender: sender, postKey: postKey)
        
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(date, forKey: "date")
        coder.encode(sender, forKey: "sender")
        coder.encode(postKey, forKey: "postKey")
    }
    
    func getKey() -> String {
        return key
    }
    
    func getType() -> NotificationType {
        return type
    }
    
    func getDate() -> Date {
        return date
    }
    
    func getSender() -> String {
        return sender
    }
    
    func getPostKey() -> String? {
        return postKey
    }
}

func < (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: Notification, rhs: Notification) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}
